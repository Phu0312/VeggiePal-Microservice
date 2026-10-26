/**
 * Tiện ích tính toán toạ độ SVG và chỉ số xu hướng cho BmiTrackerCard.
 * Tách hàm thuần để dễ dàng kiểm thử bằng node:test.
 */

const DEFAULT_WIDTH = 500;
const DEFAULT_HEIGHT = 120;
const PADDING_X = 10;
const PADDING_TOP = 20;
const PADDING_BOTTOM = 35;

/**
 * Format nhãn ngày hiển thị dưới trục hoành của biểu đồ (VD: "12/05" hoặc "Tháng 05").
 */
export function formatAxisDate(iso) {
  if (!iso) return "—";
  try {
    const d = new Date(iso);
    if (Number.isNaN(d.getTime())) return "—";
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    return `${day}/${month}`;
  } catch {
    return "—";
  }
}

/**
 * Tính toạ độ SVG (line & area path) từ danh sách bản ghi đã sắp xếp theo thời gian (cũ -> mới).
 * Yêu cầu tối thiểu 2 điểm. Nếu ít hơn 2 điểm, trả về null.
 */
export function calcChartPoints(records, metric = "bmi", width = DEFAULT_WIDTH, height = DEFAULT_HEIGHT) {
  if (!Array.isArray(records) || records.length < 2) {
    return null;
  }

  const values = records.map((r) => {
    const v = Number(r?.[metric]);
    return Number.isFinite(v) ? v : 0;
  });

  const minVal = Math.min(...values);
  const maxVal = Math.max(...values);
  const span = maxVal - minVal || 1; // tránh chia cho 0 nếu tất cả điểm bằng nhau
  const usableHeight = height - PADDING_TOP - PADDING_BOTTOM;

  const points = values.map((val, i) => {
    const x = PADDING_X + (i * (width - PADDING_X * 2)) / (values.length - 1);
    // Giá trị cao hơn thì y nhỏ hơn (nằm cao hơn trên SVG)
    const y = PADDING_TOP + ((maxVal - val) / span) * usableHeight;
    return {
      x: Number(x.toFixed(1)),
      y: Number(y.toFixed(1)),
      value: val,
      date: formatAxisDate(records[i]?.recordedAt),
      isLast: i === values.length - 1,
    };
  });

  const linePath = points.map((p, i) => `${i === 0 ? "M" : "L"} ${p.x} ${p.y}`).join(" ");
  const areaPath = `${linePath} L ${points[points.length - 1].x} ${height} L ${points[0].x} ${height} Z`;

  return { points, linePath, areaPath };
}

/**
 * Tính độ lệch, số ngày và câu nhận xét xu hướng giữa bản ghi đầu và bản ghi mới nhất.
 */
export function calcTrendAnalysis(records, metric = "bmi") {
  if (!Array.isArray(records) || records.length < 2) {
    return null;
  }

  const first = records[0];
  const latest = records[records.length - 1];

  const firstVal = Number(first?.[metric]);
  const latestVal = Number(latest?.[metric]);

  if (!Number.isFinite(firstVal) || !Number.isFinite(latestVal)) {
    return null;
  }

  const diff = Number((latestVal - firstVal).toFixed(1));
  const unit = metric === "bmi" ? "điểm" : "kg";

  let days = 1;
  try {
    const tFirst = new Date(first.recordedAt).getTime();
    const tLatest = new Date(latest.recordedAt).getTime();
    if (!Number.isNaN(tFirst) && !Number.isNaN(tLatest)) {
      days = Math.max(1, Math.round(Math.abs(tLatest - tFirst) / (1000 * 60 * 60 * 24)));
    }
  } catch {
    days = 1;
  }

  let highlight;
  if (diff < 0) {
    highlight = `Chỉ số giảm ${Math.abs(diff)} ${unit}`;
  } else if (diff > 0) {
    highlight = `Chỉ số tăng ${diff} ${unit}`;
  } else {
    highlight = "Chỉ số duy trì ổn định";
  }

  const detail = `sau ${days} ngày theo dõi thể trạng`;

  return {
    firstVal,
    latestVal,
    diff,
    days,
    unit,
    highlight,
    detail,
  };
}
