import 'package:flutter/material.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/providers/auth_provider.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/auth/data/associate_model.dart';
import 'package:portal_assoc/features/auth/presentation/auth_controller.dart';
import 'package:portal_assoc/shared/widgets/dropdown_input.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';

class CompaniesDropdown extends StatefulWidget {
  const CompaniesDropdown({super.key, required this.authController, required this.authProvider});

  final AuthController authController;
  final AuthProvider authProvider;

  @override
  State<CompaniesDropdown> createState() => CompaniesDropdownState();
}

class CompaniesDropdownState extends State<CompaniesDropdown> {
  int company = 0;

  @override
  initState() {
    widget.authController.findCompanies();
    super.initState();
  }

  _changeCompany(int? value) {
    setState(() {
      company = value!;
    });
    widget.authProvider.setCompany(value!);
  }

  selectedCompany(List<CompaniesModel?> companies) {
    bool condition = companies.any((e) => e!.id == widget.authProvider.company);
    if (condition) {
      company = widget.authProvider.company;
    } else {
      company = companies[0]!.id!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<StateApp<dynamic>>(
      valueListenable: widget.authController.stateCompanies,
      builder: (context, stateCompanies, child) {
        if (stateCompanies is SuccessState) {
          selectedCompany(stateCompanies.data as List<CompaniesModel?>);
        }
        return stateCompanies is LoadingState
            ? const LoadingContainer(width: 250, height: 40, borderRadius: AppRadius.large)
            : stateCompanies is SuccessState
                ? SizedBox(
                    width: 250,
                    child: DropdownInput(
                      value: company,
                      items: stateCompanies.data
                          .map<DropdownMenuItem<int>>((CompaniesModel? e) => DropdownMenuItem(
                                value: e!.id,
                                child: Text(e.name.toString()),
                              ))
                          .toList(),
                      onChanged: (a) async {
                        _changeCompany(a);
                      },
                    ),
                  )
                : Container();
      },
    );
  }
}
