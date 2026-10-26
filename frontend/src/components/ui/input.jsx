import { cn } from "cn"

import { inputVariants } from "@/components/ui/variants/input-variants"

// Ô nhập dùng chung. `ref` và các prop của react-hook-form (`{...register("x")}`)
// truyền thẳng xuống <input> (React 19 cho phép nhận `ref` như một prop thường).
function Input({ className, variant, type = "text", ...props }) {
  return (
    <input
      type={type}
      data-slot="input"
      className={cn(inputVariants({ variant }), className)}
      {...props}
    />
  )
}

export { Input }
