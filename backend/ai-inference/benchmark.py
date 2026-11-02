"""Run supplied authenticated feature cases and write measured latency/status CSV."""
import csv
import json
import subprocess
import sys
import time
import urllib.error
import urllib.request


def run(case):
    payload = None if "body" not in case else json.dumps(case["body"], ensure_ascii=False).encode("utf-8")
    headers = {"Content-Type": "application/json", **case.get("headers", {})}
    request = urllib.request.Request(case["url"], data=payload, headers=headers,
                                     method=case.get("method", "GET"))
    start = time.perf_counter_ns()
    try:
        with urllib.request.urlopen(request, timeout=180) as response:
            response.read()
            status = response.status
    except urllib.error.HTTPError as error:
        status = error.code
    except (urllib.error.URLError, TimeoutError):
        status = 0
    return status, (time.perf_counter_ns() - start) / 1_000_000


def resources():
    """Best-effort instantaneous samples; blanks mean a monitoring tool was unavailable."""
    values = {"container_ram": "", "container_cpu": "", "gpu_vram_mib": "", "gpu_utilization": ""}
    try:
        result = subprocess.run(["docker", "stats", "--no-stream", "--format", "{{json .}}",
                                 "veggiepal-local-ai-llama-1"], capture_output=True, text=True,
                                timeout=10, check=True)
        item = json.loads(result.stdout.splitlines()[0])
        values["container_ram"] = item.get("MemUsage", "")
        values["container_cpu"] = item.get("CPUPerc", "")
    except (OSError, subprocess.SubprocessError, ValueError, IndexError):
        pass
    try:
        result = subprocess.run(["nvidia-smi", "--query-gpu=memory.used,utilization.gpu",
                                 "--format=csv,noheader,nounits"], capture_output=True, text=True,
                                timeout=10, check=True)
        values["gpu_vram_mib"], values["gpu_utilization"] = result.stdout.splitlines()[0].split(",", 1)
    except (OSError, subprocess.SubprocessError, ValueError, IndexError):
        pass
    return values


def main():
    if len(sys.argv) != 3:
        raise SystemExit("usage: benchmark.py cases.json results.csv")
    with open(sys.argv[1], encoding="utf-8") as source:
        cases = json.load(source)
    totals = {}
    with open(sys.argv[2], "w", newline="", encoding="utf-8") as output:
        writer = csv.DictWriter(output, fieldnames=["feature", "phase", "status", "success", "end_to_end_ms",
                                                       "inference_ms", "inference_status", "container_ram",
                                                       "container_cpu", "gpu_vram_mib", "gpu_utilization"])
        writer.writeheader()
        for case in cases:
            for phase in ("cold_request", "warm_request", "warm_request", "warm_request"):
                status, latency = run(case)
                count, passed = totals.get(case["feature"], (0, 0))
                totals[case["feature"]] = (count + 1, passed + int(200 <= status < 300))
                inference_status, inference_ms = run(case["inference"]) if "inference" in case else ("", "")
                writer.writerow({"feature": case["feature"], "phase": phase, "status": status,
                                 "success": 200 <= status < 300, "end_to_end_ms": round(latency, 2),
                                 "inference_ms": round(inference_ms, 2) if inference_ms != "" else "",
                                 "inference_status": inference_status, **resources()})
    with open(sys.argv[2] + ".summary.csv", "w", newline="", encoding="utf-8") as output:
        writer = csv.writer(output)
        writer.writerow(["feature", "requests", "successes", "failures", "success_rate", "failure_rate"])
        for feature, (count, passed) in totals.items():
            writer.writerow([feature, count, passed, count - passed,
                             round(passed / count, 4), round((count - passed) / count, 4)])


if __name__ == "__main__":
    main()
