String formatDateTime(String? isoString) {
  if (isoString == null || isoString.isEmpty) {
    return "";
  }

  try {
    final date = DateTime.parse(isoString).toLocal();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/$year às $hour:$minute';
  } catch (e) {
    // Retorna a string original caso o parse falhe
    return isoString;
  }
}
