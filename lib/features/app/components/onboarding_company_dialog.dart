import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/features/register/companies_model.dart';
import 'package:portal_assoc/features/register/register_controller.dart';
import 'package:portal_assoc/features/register/register_repository.dart';
import 'package:portal_assoc/features/register/register_usecase.dart';
import 'package:portal_assoc/shared/widgets/custom_input.dart';

// ─── Design tokens (mirrors _DS do resto do projeto) ─────────────────────────
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const successAccent = Color(0xFF00B473);
  static const successSoft = Color(0xFFE8F8F1);
  static const rXxxl = 28.0;
  static const rXl = 16.0;
}

class OnboardingCompanyDialog extends StatefulWidget {
  const OnboardingCompanyDialog({super.key, required this.authController});

  final AuthController authController;

  @override
  State<OnboardingCompanyDialog> createState() => _OnboardingCompanyDialogState();
}

class _OnboardingCompanyDialogState extends State<OnboardingCompanyDialog> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  late final AnimationController _enterCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  );
  late final Animation<double> _fadeAnim = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
  late final Animation<Offset> _slideAnim = Tween<Offset>(
    begin: const Offset(0, 0.06),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));

  final RegisterController _registerCtrl = RegisterController(
    StartState(),
    RegisterUseCase(RegisterRepository()),
  );

  bool _success = false;

  @override
  void initState() {
    super.initState();
    _enterCtrl.forward();
    _registerCtrl.stateCreateCompany.addListener(_onSaveResult);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    _registerCtrl.stateCreateCompany.removeListener(_onSaveResult);
    _enterCtrl.dispose();
    super.dispose();
  }

  void _onSaveResult() {
    final state = _registerCtrl.stateCreateCompany.value;
    if (state is SuccessState && mounted && !_success) {
      _success = true;
      // Recarrega lista de empresas antes de fechar
      widget.authController.findCompanies().then((_) {
        // Incrementa o notifier para o HomePage recarregar o dashboard
        widget.authController.homeRefreshNotifier.value++;
        if (mounted) Navigator.of(context).pop(true);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _registerCtrl.createCompany(
      CompaniesModel.fromJson({
        'name': _nameCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
      }),
      0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: _DS.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(_DS.rXxxl),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(36),
                  child: ValueListenableBuilder<StateApp>(
                    valueListenable: _registerCtrl.stateCreateCompany,
                    builder: (context, state, _) {
                      if (_success) return const _SuccessView();
                      return _FormView(
                        formKey: _formKey,
                        nameCtrl: _nameCtrl,
                        descCtrl: _descCtrl,
                        phoneCtrl: _phoneCtrl,
                        isLoading: state is LoadingState,
                        onSubmit: _submit,
                        errorMessage: state is ErrorState ? state.message : null,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Form view ────────────────────────────────────────────────────────────────
class _FormView extends StatelessWidget {
  const _FormView({
    required this.formKey,
    required this.nameCtrl,
    required this.descCtrl,
    required this.phoneCtrl,
    required this.isLoading,
    required this.onSubmit,
    this.errorMessage,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameCtrl;
  final TextEditingController descCtrl;
  final TextEditingController phoneCtrl;
  final bool isLoading;
  final VoidCallback onSubmit;
  final String? errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ícone central
        Center(
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: _DS.brandBlue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(_DS.rXl),
            ),
            child: const Icon(
              LucideIcons.store,
              size: 28,
              color: _DS.brandBlue,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Título
        const Text(
          'Configure sua empresa',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            color: _DS.ink,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),

        // Subtítulo
        const Text(
          'Para começar a usar o sistema, preencha os dados da sua empresa.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: _DS.steel,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Formulário
        Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomInput(
                controller: nameCtrl,
                title: 'Nome do negócio',
                icon: LucideIcons.building2,
                hint: 'Burger Plus',
                keyboardType: TextInputType.text,
                floatingLabel: false,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nome obrigatório' : null,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: descCtrl,
                title: 'Descrição',
                icon: LucideIcons.fileText,
                hint: 'Breve descrição do seu negócio',
                keyboardType: TextInputType.text,
                floatingLabel: false,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Descrição obrigatória' : null,
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 16),
              CustomInput(
                controller: phoneCtrl,
                title: 'Telefone',
                icon: LucideIcons.phone,
                hint: '(27) 9 9999-9999',
                keyboardType: TextInputType.phone,
                floatingLabel: false,
                inputFormatters: [MaskedInputFormatter('(##) # ####-####')],
                onEditingComplete: () => FocusScope.of(context).nextFocus(),
              ),

              // Mensagem de erro
              if (errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE53935).withValues(alpha: 0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(LucideIcons.alertCircle, size: 15, color: Color(0xFFE53935)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Erro ao salvar. Tente novamente.',
                          style: TextStyle(fontSize: 12, color: Color(0xFFE53935)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Botão
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: isLoading ? null : onSubmit,
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.brandBlue,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: _DS.brandBlue.withValues(alpha: 0.5),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Salvar e continuar',
                              style: TextStyle(
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Success view ─────────────────────────────────────────────────────────────
class _SuccessView extends StatelessWidget {
  const _SuccessView();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: const BoxDecoration(
            color: _DS.successSoft,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            LucideIcons.checkCircle2,
            size: 32,
            color: _DS.successAccent,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Empresa cadastrada!',
          style: TextStyle(
            fontSize: 20,
            color: _DS.ink,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'Configurando seu painel...',
          style: TextStyle(fontSize: 13, color: _DS.stone),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue),
        ),
      ],
    );
  }
}
