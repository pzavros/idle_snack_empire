String formatCoins(double value) {
  if (value.isNaN || value.isInfinite) {
    return '0';
  }

  final abs = value.abs();
  if (abs < 1000) {
    return value.toStringAsFixed(abs >= 100 ? 0 : 1);
  }

  const suffixes = ['K', 'M', 'B', 'T', 'Qa'];
  var scaled = abs;
  var suffixIndex = -1;

  while (scaled >= 1000 && suffixIndex < suffixes.length - 1) {
    scaled /= 1000;
    suffixIndex += 1;
  }

  final decimals = scaled >= 100 ? 0 : (scaled >= 10 ? 1 : 2);
  final sign = value < 0 ? '-' : '';
  return '$sign${scaled.toStringAsFixed(decimals)}${suffixes[suffixIndex]}';
}

String formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds}s';
  }
  return '${seconds}s';
}
