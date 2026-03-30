/// 2026-style scoring (no fastest-lap point).
abstract final class ChampionshipPoints {
  ChampionshipPoints._();

  /// Grand Prix: P1–P10.
  static const List<int> grandPrix = [25, 18, 15, 12, 10, 8, 6, 4, 2, 1];

  /// Sprint (8 places).
  static const List<int> sprint = [8, 7, 6, 5, 4, 3, 2, 1];

  static int gpPointsForPosition(int position) {
    if (position < 1 || position > grandPrix.length) return 0;
    return grandPrix[position - 1];
  }

  static int sprintPointsForPosition(int position) {
    if (position < 1 || position > sprint.length) return 0;
    return sprint[position - 1];
  }

  /// Naive upper bound: remaining GP rounds × 25 (no sprint in this bound).
  static int maxGpPointsRemaining(int remainingGrandPrixRounds) =>
      remainingGrandPrixRounds * grandPrix.first;
}
