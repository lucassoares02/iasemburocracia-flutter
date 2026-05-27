import 'package:flutter/material.dart';
import 'package:portal_assoc/features/additional_info/additional_info_page.dart';
import 'package:portal_assoc/features/companies/widgets/business_address.dart';
import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_page.dart';
import 'package:portal_assoc/features/connections/connections_page.dart';
import 'package:portal_assoc/features/menu_items/menu_items_page.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_page.dart';
import 'package:portal_assoc/features/promotions/promotions_page.dart';
import 'package:portal_assoc/features/purchase_goals/purchase_goals_page.dart';
import 'package:portal_assoc/features/upsell/upsell_rules_page.dart';
import '../../core/state/app_state.dart';
import 'companies_controller.dart';
import 'companies_repository.dart';
import 'companies_usecase.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/companies/widgets/business_informations.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─── Design tokens ────────────────────────────────────────────────────────────
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const brandBlue = Color(0xFF4262FF);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const hairlineSoft = Color(0xFFEEF0F3);
  static const slate = Color(0xFF555A6A);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const muted = Color(0xFFA5A8B5);
  static const successAccent = Color(0xFF00B473);
  static const successSoft = Color(0xFFE8F8F1);
  static const danger = Color(0xFFE53935);
  static const dangerSoft = Color(0xFFFFEBEA);
  static const warningAccent = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFFF8E1);
  static const surfacePricing = Color(0xFFF5F3FF);
  static const rXl = 16.0;
  static const rLg = 12.0;
  static const rMd = 8.0;
}

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  late final CompaniesController controller = CompaniesController(StartState(), CompaniesUseCase(CompaniesRepository()));
  int selectedIndex = 0;
  static const _menuWidth = 260.0;

  @override
  void initState() {
    super.initState();
    getSharedPreferences();
  }

  setSharedPreferences(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      prefs.setInt('business_settings_selected_index', index);
    } catch (e) {
      debugPrint("Error Set Shared Preferences Account: $e");
    }
  }

  getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        selectedIndex = prefs.getInt('business_settings_selected_index') ?? 0;
      });
    } catch (e) {
      debugPrint("Error Set Shared Preferences Account: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItems = <({String label, IconData icon})>[
      (label: "Informações da Empresa", icon: LucideIcons.store),
      (label: "Endereço", icon: LucideIcons.mapPin),
      (label: "Horários", icon: LucideIcons.clock),
      (label: "Cardápio", icon: LucideIcons.beef),
      (label: "Promoções", icon: LucideIcons.badgePercent),
      (label: "Formas de pagamento", icon: LucideIcons.creditCard),
      (label: "Informações adicionais", icon: LucideIcons.badgeInfo),
      (label: "Conexões", icon: LucideIcons.qrCode),
      (label: "Upsell Inteligente", icon: LucideIcons.zap),
      (label: "Objetivo de Compra", icon: LucideIcons.target),
    ];

    return Scaffold(
      backgroundColor: _DS.surface,
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Row(
                children: [
                  Container(
                    width: _menuWidth,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(menuItems.length, (i) {
                        final item = menuItems[i];
                        final active = selectedIndex == i;
                        return _BusinessNavItem(
                          label: item.label,
                          icon: item.icon,
                          active: active,
                          onTap: () {
                            setState(() => selectedIndex = i);
                            setSharedPreferences(i);
                          },
                        );
                      }),
                    ),
                  ),
                  const SizedBox(width: 18),
                  if (selectedIndex == 0) BusinessInformations(controller: controller),
                  if (selectedIndex == 1) BusinessAddress(controller: controller),
                  if (selectedIndex == 2) const CompanyOpeningHoursPage(),
                  if (selectedIndex == 3) const MenuItemsPage(),
                  if (selectedIndex == 4) const PromotionsPage(),
                  if (selectedIndex == 5) const PaymentMethodsPage(),
                  if (selectedIndex == 6) const AdditionalInfoPage(),
                  if (selectedIndex == 7) const ConnectionsPage(),
                  if (selectedIndex == 8) const UpsellRulesPage(),
                  if (selectedIndex == 9) const PurchaseGoalsPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BusinessNavItem extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const _BusinessNavItem({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  State<_BusinessNavItem> createState() => _BusinessNavItemState();
}

class _BusinessNavItemState extends State<_BusinessNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final selectedBg = Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12);
    final selectedFg = Theme.of(context).colorScheme.secondary;
    final idleFg = Theme.of(context).colorScheme.onSurface;
    final hoverFg = Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.72);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            color: widget.active ? selectedBg : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.active ? selectedFg.withValues(alpha: 0.30) : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                size: 18,
                color: widget.active ? selectedFg : (_hovered ? hoverFg : idleFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    color: widget.active ? selectedFg : (_hovered ? hoverFg : idleFg),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
