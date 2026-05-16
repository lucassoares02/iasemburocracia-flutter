import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/users/data/users_repository.dart';
import 'package:portal_assoc/features/users/presentation/controllers/users_controller.dart';
import 'package:portal_assoc/features/users/presentation/widgets/alert_dialog_user.dart';
import 'package:portal_assoc/features/users/presentation/widgets/data_source_users.dart';
import 'package:portal_assoc/shared/widgets/custom_search.dart';
import 'package:portal_assoc/shared/widgets/loading_list.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';
import 'package:portal_assoc/shared/widgets/table.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> with TickerProviderStateMixin {
  UsersController usersController = UsersController(StartState(), UsersRepository());

  @override
  void initState() {
    usersController.getUsers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: AppSpacing.mediumPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    "Usuários",
                    style: AppTextStyles.title,
                  ),
                  Row(
                    children: [
                      SpecialButton(
                        color: Theme.of(context).colorScheme.primary,
                        icon: LucideIcons.plus,
                        label: "Adicionar",
                        onPressButton: () {
                          showDialog(
                              context: context,
                              builder: (_) {
                                return AlertDialogUser(usersController: usersController);
                              });
                        },
                      ),
                      const Spacing(),
                      CustomSearch(
                        onSearch: (value) {
                          usersController.search(value);
                        },
                      ),
                    ],
                  ),
                ],
              ),
              const Spacing(),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder(
                  valueListenable: usersController.stateUsers,
                  builder: (context, state, child) {
                    return state is LoadingState
                        ? const LoadingList()
                        : state is SuccessState
                            ? AppTable(
                                rowsPerPage: 10,
                                columns: const [
                                  DataColumn(label: Text("Id")),
                                  DataColumn(label: Text("Nome")),
                                  DataColumn(label: Text("Email")),
                                  DataColumn(label: Text("Status")),
                                  DataColumn(label: Text("Tipo")),
                                  DataColumn(label: Text("Lojas")),
                                  DataColumn(label: Text("Criado em")),
                                ],
                                dataSourceTable: DataSourceUsers(
                                  usersController: usersController,
                                  list: state.data,
                                  context: context,
                                ),
                              )
                            : Container();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
