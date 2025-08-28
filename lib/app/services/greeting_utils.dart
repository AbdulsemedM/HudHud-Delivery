class GreetingUtils {
  /// Get time-based greeting based on current hour
  static String getTimeBasedGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    
    if (hour >= 5 && hour < 12) {
      return 'Good Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Good Afternoon';
    } else if (hour >= 17 && hour < 21) {
      return 'Good Evening';
    } else {
      return 'Good Night';
    }
  }
  
  /// Get greeting with user name
  static String getGreetingWithName(String? userName) {
    final greeting = getTimeBasedGreeting();
    final name = userName ?? 'User';
    return '$greeting $name';
  }
  
  /// Get current time formatted as string
  static String getCurrentTimeFormatted() {
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}