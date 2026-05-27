import 'package:flutter/material.dart';
import 'package:flutter_multi_formatter/formatters/masked_input_formatter.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/account/account_model.dart';
import 'package:portal_assoc/features/account/account_repository.dart';
import 'package:portal_assoc/features/onboarding/setup_validation_service.dart';
import 'package:portal_assoc/features/onboarding/widgets/onboarding_design.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_horizontal_timeline.dart';
import 'package:portal_assoc/features/onboarding/widgets/setup_step_container.dart';

class PersonalStep extends StatefulWidget {
  final OnboardingSnapshot snapshot;
  final Future<void> Function() onSaved;

  const PersonalStep({
    super.key,
    required this.snapshot,
    required this.onSaved,
  });

  @override
  State<PersonalStep> createState() => _PersonalStepState();
}

class _PersonalStepState extends State<PersonalStep> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _repo = AccountRepository();
  bool _saving = false;
  String? _serverError;

  @override
  void initState() {
    super.initState();
    final acc = widget.snapshot.account;
    _nameCtrl.text = acc?.name ?? '';
    _phoneCtrl.text = acc?.phone ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _serverError = null;
    });
    try {
      final base = widget.snapshot.account;
      final updated = AccountModel.fromJson({
        'id': base?.id,
        'name': _nameCtrl.text.trim(),
        'email': base?.email,
        'phone': _phoneCtrl.text.trim(),
        'document': base?.document,
        'birthday': base?.birthday,
        'active': base?.active,
        'created_at': base?.createdAt,
      });
      final resp = await _repo.update(updated);
      if (!resp.success) {
        setState(() => _serverError = resp.message);
        return;
      }
      await widget.onSaved();
    } catch (e) {
      setState(() => _serverError = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SetupStepContainer(
      stepIndex: 0,
      descriptor: kSetupSteps[0],
      headlinePrefix: 'Etapa',
      description: 'Personalize sua conta. Esses dados aparecem no atendimento e nos relatórios.',
      footer: Row(
        children: [
          if (_serverError != null)
            Expanded(
              child: Text(_serverError!, style: const TextStyle(color: OnboardingDS.danger, fontSize: 12)),
            )
          else
            const Spacer(),
          OnboardingPrimaryButton(onPressed: _save, loading: _saving, isLast: false),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OnboardingFieldCard(
              child: TextFormField(
                controller: _nameCtrl,
                decoration: onboardingFieldDecoration(
                  'Nome completo',
                  hint: 'Como você se chama?',
                  icon: LucideIcons.user,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Informe seu nome' : null,
                style: const TextStyle(fontSize: 15, color: OnboardingDS.ink),
              ),
            ),
            const SizedBox(height: 12),
            OnboardingFieldCard(
              child: TextFormField(
                controller: _phoneCtrl,
                decoration: onboardingFieldDecoration(
                  'Telefone / WhatsApp',
                  hint: '(00) 00000-0000',
                  icon: LucideIcons.phone,
                ),
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  MaskedInputFormatter(
                    '(##) #####-####',
                    allowedCharMatcher: RegExp(r'[0-9]'),
                  ),
                ],
                validator: (v) {
                  final digits = (v ?? '').replaceAll(RegExp(r'[^0-9]'), '');
                  if (digits.length < 10) return 'Telefone inválido';
                  return null;
                },
                style: const TextStyle(fontSize: 15, color: OnboardingDS.ink),
              ),
            ),
            const SizedBox(height: 16),
            const _InfoBanner(
              icon: LucideIcons.shield,
              text: 'Usamos seu telefone apenas para identificá-lo dentro da plataforma. Não compartilhamos com terceiros.',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoBanner({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: OnboardingDS.brandBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(OnboardingDS.rMd),
        border: Border.all(color: OnboardingDS.brandBlue.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: OnboardingDS.brandBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                color: OnboardingDS.slate,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
