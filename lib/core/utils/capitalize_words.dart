String capitalizeWords(String? text) {
  if (text == null || text.isEmpty) return "";

  return text.toLowerCase().split(' ').map((word) {
    if (word.isEmpty) return "";
    return word[0].toUpperCase() + word.substring(1);
  }).join(' ');
}
