/// Adaptive polling schedule for wallet top-up / QPay status checks.
class PaymentPollSchedule {
  const PaymentPollSchedule._();

  static const fastInterval = Duration(seconds: 3);
  static const slowInterval = Duration(seconds: 10);
  static const fastPhase = Duration(seconds: 30);
  static const totalDuration = Duration(minutes: 5);

  static DateTime deadlineFrom(DateTime startedAt) =>
      startedAt.add(totalDuration);

  static Duration nextInterval({
    required DateTime startedAt,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    if (current.difference(startedAt) < fastPhase) {
      return fastInterval;
    }
    return slowInterval;
  }

  static bool isPastDeadline({
    required DateTime startedAt,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    return !current.isBefore(deadlineFrom(startedAt));
  }
}
