import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Initialises `dotenv` once for every test file under `test/`.
///
/// `flutter test` never runs `main()`, so `loadAppEnv()` is never called and
/// `dotenv.isInitialized` stays false. Fifteen test files reach the API layer
/// somewhere in their setup, and `ApiEnv.baseUrl` throws outright rather than
/// falling back:
///
///   Bad state: Env not loaded. Call loadAppEnv() before using the API.
///
/// That is not a CI artefact — it is why these 82 files could never have been
/// run as a suite. Each one that touches a data provider, a repository or any
/// Dio client fails before its first expectation.
///
/// `loadFromString` is used rather than `load`, so tests do not depend on the
/// gitignored `.env` asset existing. Note the name: this method was called
/// `testLoad` until flutter_dotenv 6.0 renamed it, and this project is on
/// ^6.0.1.
///
/// The value is the public API host. No test should reach it — anything that
/// does is making a real network call and wants a fake provider instead — but
/// a wrong host fails more honestly than an empty one.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  dotenv.loadFromString(
    envString: 'BASE_URL=https://deliveryapi.hudhudexpress.com\n',
  );
  await testMain();
}
