String formatDate(String? isoString) {
  if (isoString == null || isoString.isEmpty) {
    return "";
  }

  try {
    final date = DateTime.parse(isoString).toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    return '$day/$month/$year';
  } catch (e) {
    return isoString;
  }
}
