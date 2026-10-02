String _two(int n) => n.toString().padLeft(2, '0');

/// dd/MM/yyyy
String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// dd/MM/yyyy HH:mm
String fmtDateTime(DateTime d) => '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

/// yyyy-MM-dd (định dạng LocalDate mà backend nhận)
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

/// "Vừa xong", "5 phút trước", "3 giờ trước", "2 ngày trước", hoặc ngày đầy đủ nếu quá 30 ngày.
String timeAgo(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'Vừa xong';
  if (d.inHours < 1) return '${d.inMinutes} phút trước';
  if (d.inDays < 1) return '${d.inHours} giờ trước';
  if (d.inDays <= 30) return '${d.inDays} ngày trước';
  return fmtDate(t);
}
