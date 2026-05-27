import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tokens compartilhados pelos arquivos do onboarding.
/// Espelham `_DS` das páginas do projeto e respeitam o CLAUDE.md → "2. Padrão visual".
class OnboardingDS {
  static const Color ink = Color(0xFF1C1C1E);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color stone = Color(0xFF8E91A0);
  static const Color muted = Color(0xFFA5A8B5);
  static const Color successAccent = Color(0xFF00B473);
  static const Color successSoft = Color(0xFFE8F8F1);
  static const Color danger = Color(0xFFE53935);
  static const Color warningAccent = Color(0xFFF59E0B);
  static const Color warningSoft = Color(0xFFFFF8E1);

  static const double rFull = 9999;
  static const double rXxl = 28;
  static const double rXl = 16;
  static const double rLg = 12;
  static const double rMd = 8;
}

InputDecoration onboardingFieldDecoration(
  String label, {
  String? hint,
  IconData? icon,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: icon != null ? Icon(icon, size: 18, color: OnboardingDS.stone) : null,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OnboardingDS.rMd),
      borderSide: const BorderSide(color: OnboardingDS.hairline),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OnboardingDS.rMd),
      borderSide: const BorderSide(color: OnboardingDS.hairline),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OnboardingDS.rMd),
      borderSide: const BorderSide(color: OnboardingDS.brandBlue, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OnboardingDS.rMd),
      borderSide: const BorderSide(color: OnboardingDS.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(OnboardingDS.rMd),
      borderSide: const BorderSide(color: OnboardingDS.danger, width: 2),
    ),
    filled: true,
    fillColor: OnboardingDS.canvas,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    labelStyle: const TextStyle(color: OnboardingDS.steel, fontSize: 14),
    floatingLabelStyle: const TextStyle(color: OnboardingDS.brandBlue, fontSize: 12),
  );
}

/// Botão principal "Salvar e continuar".
class OnboardingPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final bool isLast;
  final String? label;
  final IconData? icon;

  const OnboardingPrimaryButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.isLast = false,
    this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedLabel = label ??
        (loading
            ? 'Salvando...'
            : isLast
                ? 'Concluir configuração'
                : 'Salvar e continuar');
    final resolvedIcon = icon ?? (isLast ? Icons.check_circle_outline : Icons.arrow_forward_rounded);

    return FilledButton.icon(
      onPressed: loading ? null : onPressed,
      icon: loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Icon(resolvedIcon, size: 18),
      label: Text(resolvedLabel),
      style: FilledButton.styleFrom(
        backgroundColor: OnboardingDS.ink,
        foregroundColor: Colors.white,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
        textStyle: const TextStyle(
          fontSize: 15,
        ),
      ),
    );
  }
}

class OnboardingSecondaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String label;
  final IconData? icon;

  const OnboardingSecondaryButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.arrow_back_rounded, size: 16),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: OnboardingDS.ink,
        side: const BorderSide(color: OnboardingDS.hairline),
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: const TextStyle(
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Card de campo com borda hairline soft.
class OnboardingFieldCard extends StatelessWidget {
  final Widget child;
  const OnboardingFieldCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: OnboardingDS.canvas,
        borderRadius: BorderRadius.circular(OnboardingDS.rMd),
        border: Border.all(color: OnboardingDS.hairlineSoft),
      ),
      child: child,
    );
  }
}

/// Permite somente caracteres aceitos como inteiro.
class OnboardingDigitsOnly extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final filtered = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    return TextEditingValue(
      text: filtered,
      selection: TextSelection.collapsed(offset: filtered.length),
    );
  }
}
