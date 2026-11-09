/// Live typing ke liye text diff — old aur new text me se nikalta hai ke
/// PC par kitne backspace bhejne hain aur kya type karna hai.
class TextDelta {
  final int deleteCount;
  final String insert;

  const TextDelta(this.deleteCount, this.insert);
}

TextDelta computeTextDelta(String oldText, String newText) {
  if (identical(oldText, newText) || oldText == newText) {
    return const TextDelta(0, '');
  }
  final minLen = oldText.length < newText.length ? oldText.length : newText.length;

  // common prefix
  int p = 0;
  while (p < minLen && oldText.codeUnitAt(p) == newText.codeUnitAt(p)) {
    p++;
  }
  // common suffix (prefix se overlap na ho)
  int s = 0;
  while (s < minLen - p &&
      oldText.codeUnitAt(oldText.length - 1 - s) ==
          newText.codeUnitAt(newText.length - 1 - s)) {
    s++;
  }
  final removed = oldText.length - p - s;
  final insert = newText.substring(p, newText.length - s);
  return TextDelta(removed < 0 ? 0 : removed, insert);
}
