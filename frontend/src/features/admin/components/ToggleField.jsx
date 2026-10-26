// Công tắc bật/tắt gắn với react-hook-form: <ToggleField label="..." hint="..." {...register("active")} />
// Dùng checkbox thật (ẩn) nên bàn phím và trình đọc màn hình hoạt động bình thường.
export default function ToggleField({ label, hint, ref, ...inputProps }) {
  return (
    <label className="flex cursor-pointer items-start gap-3">
      <input ref={ref} type="checkbox" role="switch" className="peer sr-only" {...inputProps} />
      <span
        aria-hidden
        className="relative mt-0.5 h-6 w-11 shrink-0 rounded-full bg-border transition peer-checked:bg-brand peer-focus-visible:ring-2 peer-focus-visible:ring-brand/40 after:absolute after:left-0.5 after:top-0.5 after:size-5 after:rounded-full after:bg-white after:shadow after:transition peer-checked:after:translate-x-5"
      />
      <span className="min-w-0">
        <span className="block text-sm font-semibold text-ink">{label}</span>
        {hint && <span className="block text-xs text-subtle">{hint}</span>}
      </span>
    </label>
  );
}
