import 'package:animated_custom_dropdown/custom_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/config/app_radius.dart';
import 'package:portal_assoc/core/config/app_spacing.dart';
import 'package:portal_assoc/core/config/app_text_styles.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/core/utils/spacing.dart';
import 'package:portal_assoc/features/users/data/user_model.dart';
import 'package:portal_assoc/features/users/presentation/controllers/users_controller.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';
import 'package:portal_assoc/shared/widgets/input_component.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';

class MenuItem {
  const MenuItem({required this.id, required this.name});

  final int id;
  final String name;
}

class AlertDialogUser extends StatefulWidget {
  const AlertDialogUser({super.key, required this.usersController, this.user});

  final UsersController usersController;
  final UserModel? user;

  @override
  State<AlertDialogUser> createState() => _AlertDialogUserState();
}

class _AlertDialogUserState extends State<AlertDialogUser> {
  final TextEditingController name = TextEditingController();
  final TextEditingController email = TextEditingController();
  int type = 2;
  bool activeUser = true;
  int? associate;
  List<MenuItem> items = [
    const MenuItem(id: 2, name: "Associado"),
    const MenuItem(id: 1, name: "Organização"),
    const MenuItem(id: 0, name: "Administrador"),
  ];

  @override
  void initState() {
    widget.usersController.selectedAssociates.clear();
    widget.usersController.stateCreateUsers.value = StartState();
    if (widget.user != null) {
      name.text = widget.user!.name ?? '';
      email.text = widget.user!.email ?? '';
      type = widget.user!.type!;
      activeUser = widget.user!.active ?? false;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      insetPadding: EdgeInsets.zero,
      contentPadding: EdgeInsets.zero,
      elevation: 0.1,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.small,
      ),
      content: SizedBox(
          width: context.screenWidth < 1400 ? context.screenWidth * 0.8 : context.screenWidth * 0.7,
          height: context.screenHeight < 800 ? context.screenHeight * 0.9 : context.screenHeight * 0.75,
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.tertiary,
                    borderRadius: BorderRadius.only(
                      topLeft: AppRadius.small.bottomLeft,
                      bottomLeft: AppRadius.small.bottomLeft,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        "assets/images/logo.svg",
                        height: 80,
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 5,
                child: Padding(
                  padding: AppSpacing.largePadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Criar Usuário", style: Theme.of(context).textTheme.titleLarge),
                      const Spacing(),
                      Row(
                        children: [
                          InputComponent(
                            controller: name,
                            title: "Nome",
                          ),
                          const Spacing(),
                          InputComponent(
                            controller: email,
                            title: "E-mail",
                          ),
                        ],
                      ),
                      const Spacing(),
                      Flexible(
                        flex: 1,
                        child: SizedBox(
                          height: 60,
                          child: CustomDropdown(
                            canCloseOutsideBounds: false,
                            items: items.map((e) => e.name).toList(),
                            onChanged: (item) {
                              final value = items.firstWhere((element) => element.name == item).id;
                              setState(() {
                                type = value;
                              });
                              if (value == 2 && widget.usersController.associates.isEmpty) {
                              } else {
                                widget.usersController.selectedAssociates.clear();
                              }
                            },
                            initialItem: type == 2
                                ? "Associado"
                                : type == 1
                                    ? "Organização"
                                    : "Administrador",
                            overlayHeight: context.screenHeight * 0.4,
                            hintText: "Selecione",
                            closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: CustomDropdownDecoration(
                              closedBorder: Border.all(
                                width: 1,
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                              ),
                              closedFillColor: Theme.of(context).colorScheme.surface,
                              expandedFillColor: Theme.of(context).colorScheme.surface,
                              closedBorderRadius: AppRadius.small,
                              expandedBorderRadius: AppRadius.small,
                              searchFieldDecoration: SearchFieldDecoration(fillColor: Theme.of(context).colorScheme.surface),
                            ),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Checkbox(
                            value: activeUser,
                            onChanged: (value) {
                              setState(() {
                                activeUser = !activeUser;
                              });
                            },
                          ),
                          Text("Usuário Ativo", style: Theme.of(context).textTheme.bodyLarge),
                        ],
                      ),
                      const Spacing(),
                      if (type == 2 || (widget.user != null && widget.user!.type == 2))
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Empresas",
                              style: TextStyle(),
                            ),
                            const Spacing(),
                            ValueListenableBuilder(
                              valueListenable: widget.usersController.stateAssociates,
                              builder: (context, stateAssociates, child) {
                                return stateAssociates is LoadingState
                                    ? const LoadingContainer()
                                    : Wrap(
                                        runSpacing: 10,
                                        spacing: 10,
                                        children: widget.usersController.selectedAssociates
                                            .map(
                                              (e) => Container(
                                                height: 40,
                                                padding: const EdgeInsets.only(top: 3, bottom: 3, left: 10),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).colorScheme.primary,
                                                  borderRadius: AppRadius.medium,
                                                ),
                                                child: IntrinsicWidth(
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        "${e.id} - ${e.name}",
                                                        style: const TextStyle(color: Colors.white),
                                                      ),
                                                      IconButton(
                                                        onPressed: () {
                                                          setState(() {
                                                            widget.usersController.selectedAssociates.remove(e);
                                                          });
                                                        },
                                                        icon: const Icon(LucideIcons.x, color: Colors.white),
                                                        iconSize: 16,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      );
                              },
                            ),
                            const Spacing(),
                            Row(
                              children: [
                                Flexible(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 40,
                                    child: ValueListenableBuilder(
                                        valueListenable: widget.usersController.stateAssociates,
                                        builder: (context, state, child) {
                                          return state is LoadingState
                                              ? const LoadingContainer(height: 40, width: double.maxFinite)
                                              : CustomDropdown.search(
                                                  canCloseOutsideBounds: false,
                                                  items: widget.usersController.associates.map((e) => "${e.id} - ${e.name}").toList(),
                                                  onChanged: (item) {
                                                    if (widget.usersController.selectedAssociates.any((element) => element.name == item)) {
                                                      return;
                                                    }
                                                    String itemSplited = item.toString().split(" - ")[1];
                                                    setState(() {
                                                      widget.usersController.selectedAssociates.add(
                                                        widget.usersController.associates.firstWhere((element) => element.name == itemSplited),
                                                      );
                                                    });
                                                  },
                                                  initialItem: associate,
                                                  overlayHeight: context.screenHeight * 0.4,
                                                  noResultFoundText: "Sem resultados",
                                                  searchHintText: "Pesquisar",
                                                  hintText: "Selecione",
                                                  closedHeaderPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                                  decoration: CustomDropdownDecoration(
                                                    closedBorder: Border.all(
                                                      width: 1,
                                                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
                                                    ),
                                                    closedFillColor: Theme.of(context).colorScheme.surface,
                                                    expandedFillColor: Theme.of(context).colorScheme.surface,
                                                    closedBorderRadius: AppRadius.small,
                                                    expandedBorderRadius: AppRadius.small,
                                                    searchFieldDecoration: SearchFieldDecoration(fillColor: Theme.of(context).colorScheme.surface),
                                                  ),
                                                );
                                        }),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      const Spacing(),
                      ValueListenableBuilder(
                          valueListenable: widget.usersController.stateCreateUsers,
                          builder: (context, stateSave, child) {
                            return Column(
                              children: [
                                if (stateSave is SuccessState && widget.user == null)
                                  Container(
                                    padding: AppSpacing.mediumPadding,
                                    margin: const EdgeInsets.only(bottom: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      borderRadius: AppRadius.small,
                                      border: Border.all(
                                        color: Colors.green.withValues(alpha: 0.5),
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Icon(LucideIcons.info, color: Colors.green.withValues(alpha: 0.5)),
                                        const Spacing(),
                                        const Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("Usuário criado com sucesso!", style: AppTextStyles.titleSmall),
                                            Text(
                                              "A senha de acesso foi enviada para o e-mail do usuário.",
                                              style: AppTextStyles.info,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                const Spacing(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (widget.user != null)
                                      ValueListenableBuilder(
                                        valueListenable: widget.usersController.stateSendEmail,
                                        builder: (context, stateSend, childSend) {
                                          return SpecialButton(
                                            label: "Enviar acesso",
                                            state: stateSend,
                                            type: 1,
                                            color: Theme.of(context).colorScheme.secondary,
                                            icon: LucideIcons.mail,
                                            loading: stateSend is LoadingState,
                                            error: stateSend is ErrorState,
                                            onPressButton: () {
                                              widget.usersController.sendEmailUser(widget.user!.id!);
                                            },
                                          );
                                        },
                                      ),
                                    const Spacing(),
                                    SpecialButton(
                                      label: "Salvar",
                                      state: stateSave,
                                      color: Theme.of(context).colorScheme.primary,
                                      icon: LucideIcons.check,
                                      loading: stateSave is LoadingState,
                                      // error: stateSave is ErrorState,
                                      onPressButton: () {
                                        if (name.text.isEmpty || email.text.isEmpty) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text("Preencha todos os campos"),
                                            ),
                                          );
                                          return;
                                        }
                                        widget.usersController.createUser(
                                          id: widget.user?.id,
                                          active: activeUser,
                                          name: name.text,
                                          email: email.text,
                                          type: type,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            );
                          })
                    ],
                  ),
                ),
              ),
            ],
          )),
    );
    ;
  }
}
