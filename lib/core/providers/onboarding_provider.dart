import 'package:flutter/foundation.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';

/// Provider que reflete o progresso real do onboarding consultando a API.
///
/// `isCompleted`, `currentStep` e o status de cada etapa são derivados do
/// [OnboardingSnapshot] retornado por [SetupValidationService]. Não há flag
/// local em SharedPreferences — a fonte da verdade é o backend.
class OnboardingProvider extends ChangeNotifier {
  final SetupValidationService _service = SetupValidationService();

  OnboardingSnapshot _snapshot = OnboardingSnapshot.empty();
  bool _loading = false;
  bool _hasLoaded = false;
  bool _isLoggedIn = false;

  OnboardingSnapshot get snapshot => _snapshot;
  bool get loading => _loading;
  bool get hasLoaded => _hasLoaded;
  bool get isCompleted => _hasLoaded && _snapshot.allComplete;
  int get currentStep => _snapshot.firstIncompleteIndex;
  int get totalSteps => _snapshot.totalSteps;
  int get completedSteps => _snapshot.completedCount;

  /// Chamado pelo AuthProvider/listener quando o login muda.
  /// Quando loga, dispara um refresh; quando desloga, limpa o estado.
  void setLoggedIn(bool value) {
    if (_isLoggedIn == value) return;
    _isLoggedIn = value;
    if (value) {
      refresh();
    } else {
      _snapshot = OnboardingSnapshot.empty();
      _hasLoaded = false;
      _loading = false;
      notifyListeners();
    }
  }

  /// Recarrega o snapshot a partir da API. Se [silent] for true, não emite
  /// loading=true (usado quando o caller já mostra um loader local).
  Future<void> refresh({bool silent = false}) async {
    if (!silent) {
      _loading = true;
      notifyListeners();
    }
    try {
      _snapshot = await _service.snapshot();
    } finally {
      _loading = false;
      _hasLoaded = true;
      notifyListeners();
    }
  }
}
