String invertDateFormat(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return "";
  }

  try {
    final parts = dateString.split("/");

    if (parts.length != 3) return dateString;

    final day = parts[0].padLeft(2, '0');
    final month = parts[1].padLeft(2, '0');
    final year = parts[2];

    return "$month/$day/$year";
  } catch (e) {
    return dateString;
  }
}
