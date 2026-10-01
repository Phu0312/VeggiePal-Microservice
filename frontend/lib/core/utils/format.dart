String _two(int n) => n.toString().padLeft(2, '0');

/// dd/MM/yyyy
String fmtDate(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

/// dd/MM/yyyy HH:mm
String fmtDateTime(DateTime d) => '${fmtDate(d)} ${_two(d.hour)}:${_two(d.minute)}';

/// yyyy-MM-dd (định dạng LocalDate mà backend nhận)
String isoDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
