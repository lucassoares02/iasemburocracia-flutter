// Imports updated
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/features/account/widgets/account_information.dart';
import 'package:portal_assoc/shared/widgets/button_side.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/app_state.dart';
import 'account_controller.dart';
import 'account_repository.dart';
import 'account_usecase.dart';

class AccountPage extends StatefulWidget {
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final AccountController controller = AccountController(StartState(), AccountUseCase(AccountRepository()));
  int selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    getSharedPreferences();
  }

  getSharedPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      setState(() {
        selectedIndex = prefs.getInt('account_selected_index') ?? 0;
      });
    } catch (e) {
      debugPrint("Error Set Shared Preferences Account: $e");
    }
  }

  setSharedPreferences(int index) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      prefs.setInt('account_selected_index', index);
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
                        description: "Informações da Conta",
                        icon: LucideIcons.user,
                        onTap: () {
                          setState(() {
                            selectedIndex = 0;
                          });
                          setSharedPreferences(0);
                        },
                      ),
                      // ButtonSide(
                      //     selected: selectedIndex == 1,
                      //     description: "Minha empresa",
                      //     icon: LucideIcons.store,
                      //     onTap: () {
                      //       setState(() {
                      //         selectedIndex = 1;
                      //       });
                      //       setSharedPreferences(1);
                      //     }),
                      ButtonSide(
                          selected: false,
                          description: "Sair",
                          icon: LucideIcons.logOut,
                          onTap: () {
                            final authProvider = Provider.of<AuthProvider>(context, listen: false);
                            authProvider.logout();
                          }),
                    ],
                  ),
                  if (selectedIndex == 0) AccountInformation(controller: controller),
                  // if (selectedIndex == 1) Companies(controller: controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
