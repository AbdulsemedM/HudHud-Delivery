class GreetingUtils {
  static String getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
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
  
  static String getGreetingWithName(String? name) {
    final greeting = getTimeBasedGreeting();
    final displayName = name ?? 'User';
    return '$greeting $displayName';
  }
}