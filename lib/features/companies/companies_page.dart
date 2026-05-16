import 'package:flutter/material.dart';
import 'package:portal_assoc/features/additional_info/additional_info_page.dart';
import 'package:portal_assoc/features/companies/widgets/business_address.dart';
import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_page.dart';
import 'package:portal_assoc/features/connections/connections_page.dart';
import 'package:portal_assoc/features/menu_items/menu_items_page.dart';
import 'package:portal_assoc/features/payment_methods/payment_methods_page.dart';
import '../../core/state/app_state.dart';
import 'companies_controller.dart';
import 'companies_repository.dart';
import 'companies_usecase.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/companies/widgets/business_informations.dart';
import 'package:portal_assoc/shared/widgets/button_side.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CompaniesPage extends StatefulWidget {
  const CompaniesPage({super.key});

  @override
  State<CompaniesPage> createState() => _CompaniesPageState();
}

class _CompaniesPageState extends State<CompaniesPage> {
  late final CompaniesController controller = CompaniesController(StartState(), CompaniesUseCase(CompaniesRepository()));
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
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
    return Scaffold(
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(
            child: Container(
              margin: const EdgeInsets.only(top: 40),
              constraints: const BoxConstraints(maxWidth: 1300),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ButtonSide(
                        selected: selectedIndex == 0,
                        description: "Informações da Empresa",
                        icon: LucideIcons.store,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                          setSharedPreferences(0);
                        },
                      ),
                      ButtonSide(
                          selected: selectedIndex == 1,
                          description: "Endereço",
                          icon: LucideIcons.mapPin,
                          onTap: () {
                            setState(() {
                              selectedIndex = 1;
                            });
                            setSharedPreferences(1);
                          }),
                      ButtonSide(
                          selected: selectedIndex == 2,
                          description: "Horários",
                          icon: LucideIcons.clock,
                          onTap: () {
                            setState(() {
                              selectedIndex = 2;
                            });
                            setSharedPreferences(2);
                          }),
                      ButtonSide(
                          selected: selectedIndex == 3,
                          description: "Cardápio",
                          icon: LucideIcons.beef,
                          onTap: () {
                            setState(() {
                              selectedIndex = 3;
                            });
                            setSharedPreferences(3);
                          }),
                      ButtonSide(
                          selected: selectedIndex == 4,
                          description: "Formas de pagamento",
                          icon: LucideIcons.creditCard,
                          onTap: () {
                            setState(() {
                              selectedIndex = 4;
                            });
                            setSharedPreferences(4);
                          }),
                      ButtonSide(
                          selected: selectedIndex == 5,
                          description: "Informações adicionais",
                          icon: LucideIcons.badgeInfo,
                          onTap: () {
                            setState(() {
                              selectedIndex = 5;
                            });
                            setSharedPreferences(5);
                          }),
                      ButtonSide(
                          selected: selectedIndex == 6,
                          description: "Conexões",
                          icon: LucideIcons.qrCode,
                          onTap: () {
                            setState(() {
                              selectedIndex = 6;
                            });
                            setSharedPreferences(6);
                          }),
                    ],
                  ),
                  if (selectedIndex == 0) BusinessInformations(controller: controller),
                  if (selectedIndex == 1) BusinessAddress(controller: controller),
                  if (selectedIndex == 2) const CompanyOpeningHoursPage(),
                  if (selectedIndex == 3) const MenuItemsPage(),
                  if (selectedIndex == 4) const PaymentMethodsPage(),
                  if (selectedIndex == 5) const AdditionalInfoPage(),
                  if (selectedIndex == 6) const ConnectionsPage(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
