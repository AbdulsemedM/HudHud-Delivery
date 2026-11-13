import 'package:flutter/foundation.dart';

import 'data/cancellation_models.dart';
import 'data/cancellation_repository.dart';

/// App-wide cache of the customer's cancellation standing.
///
/// [penaltyEnabled] switches the cancel rules: when on, a customer may cancel
/// after a courier is assigned (until pickup) and the server adds penalty
/// points; when off (older backend, guest) the old rule stays — no cancel
/// once a courier is assigned.
class CancellationPolicyController extends ChangeNotifier {
  CancellationPolicyController._({CancellationRepository? repository})
      : _repository = repository;

  static CancellationPolicyController instance =
      CancellationPolicyController._();

  @visibleForTesting
  static void resetForTest({CancellationRepository? repository}) {
    instance = CancellationPolicyController._(repository: repository);
  }

  CancellationRepository? _repository;
  CancellationRepository get _repo =>
      _repository ??= CancellationRepository();

  CancellationStanding? _standing;
  DateTime? _fetchedAt;
  Future<CancellationStanding?>? _inFlight;

  /// Last known standing (null until loaded).
  CancellationStanding? get standing => _standing;

  /// Server has the penalty rules switched on.
  bool get penaltyEnabled => _standing?.enabled ?? false;

  /// Loads the standing; reuses a fresh copy unless [force].
  Future<CancellationStanding?> refresh({bool force = false}) {
    final fresh = _fetchedAt != null &&
        DateTime.now().difference(_fetchedAt!) < const Duration(minutes: 2);
    if (!force && _standing != null && fresh) {
      return Future.value(_standing);
    }
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<CancellationStanding?> _load() async {
    final next = await _repo.fetchStanding();
    if (next != null) {
      _standing = next;
      _fetchedAt = DateTime.now();
      notifyListeners();
    }
    return _standing;
  }

  /// Forget everything (logout / account switch).
  void clear() {
    _standing = null;
    _fetchedAt = null;
    notifyListeners();
  }
}
