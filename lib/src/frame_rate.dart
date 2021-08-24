class FrameRate {
  const FrameRate(this.framesPerSecond) : assert(framesPerSecond > 0);
  const FrameRate._special(this.framesPerSecond);

  static const max = FrameRate._special(0);
  static const composition = FrameRate._special(-1);

  final double framesPerSecond;
}
