/// How many sign-in screens are currently in the widget tree.
///
/// A 401 pushes the customer back to sign in, and that push has to be skipped
/// when they are already there — otherwise a stale token produces a stack of
/// identical screens, one per failed request.
///
/// It is a COUNT, not a flag, because there are two of these screens now:
/// AuthEntryScreen (the phone number, the root) and LoginScreen (the password
/// form, pushed on top of it). With a single boolean, popping the password
/// screen back to the phone screen would clear it while a sign-in screen was
/// still on screen, and the next 401 would push a third.
int _authScreensOnScreen = 0;

bool get authScreenIsActive => _authScreensOnScreen > 0;

void authScreenMounted() => _authScreensOnScreen++;

void authScreenUnmounted() {
  if (_authScreensOnScreen > 0) _authScreensOnScreen--;
}
