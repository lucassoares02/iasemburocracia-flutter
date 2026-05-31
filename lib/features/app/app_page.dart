import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/app/components/header.dart';
import 'package:portal_assoc/features/app/components/onboarding_company_dialog.dart';
import 'package:portal_assoc/features/auth/data/associate_model.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:provider/provider.dart';

class AppPage extends StatefulWidget {
  final Widget child;

  const AppPage({super.key, required this.child});

  @override
  State<AppPage> createState() => _AppPageState();
}

class _AppPageState extends State<AppPage> {
  AuthController? _authController;

  bool _dialogShown = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ctrl = context.read<AuthController>();
    if (_authController == ctrl) return;
    _authController?.stateCompanies.removeListener(_checkCompanies);
    _authController = ctrl;
    _authController?.stateCompanies.addListener(_checkCompanies);
    _syncCompanies();
  }

  Future<void> _syncCompanies() async {
    final ctrl = _authController;
    if (ctrl == null || !mounted) return;
    await ctrl.findCompanies();
    if (!mounted) return;
    await context.read<AuthProvider>().loadCompany();
  }

  @override
  void dispose() {
    _authController?.stateCompanies.removeListener(_checkCompanies);
    super.dispose();
  }

  void _checkCompanies() {
    if (_dialogShown || !mounted) return;
    final state = _authController?.stateCompanies.value;
    if (state is SuccessState) {
      final companies = state.data as List<CompaniesModel>;
      if (companies.isEmpty) {
        _dialogShown = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            barrierColor: Colors.black.withValues(alpha: 0.55),
            builder: (_) =>
                OnboardingCompanyDialog(authController: _authController!),
          ).then((success) {
            // Permite mostrar novamente se o usuário precisar (ex: falha parcial)
            if (success != true) _dialogShown = false;
          });
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: EdgeInsetsGeometry.only(
                  top: AppSpacing.extraLargePadding.top,
                  left: AppSpacing.extraLargePadding.left,
                  right: AppSpacing.extraLargePadding.right,
                ),
                child: Column(
                  children: [
                    Header(controller: _authController!),
                    Expanded(child: widget.child),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
