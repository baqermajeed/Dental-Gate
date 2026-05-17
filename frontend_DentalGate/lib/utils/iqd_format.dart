/// تجميع أرقام الراتب بفواصل (مثل 1,000,000) لعرض LTR داخل واجهة عربية.
String formatIqdWithCommas(int value) {
  final s = value.abs().toString();
  final parts = <String>[];
  var rest = s;
  while (rest.length > 3) {
    parts.insert(0, rest.substring(rest.length - 3));
    rest = rest.substring(0, rest.length - 3);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return parts.join(',');
}
