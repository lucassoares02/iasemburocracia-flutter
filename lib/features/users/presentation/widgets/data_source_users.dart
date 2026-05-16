import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/utils/format_date.dart';
import 'package:portal_assoc/features/users/data/user_model.dart';
import 'package:portal_assoc/features/users/presentation/controllers/users_controller.dart';
import 'package:portal_assoc/features/users/presentation/widgets/alert_dialog_user.dart';

class DataSourceUsers extends DataTableSource {
  DataSourceUsers({required this.list, required this.context, required this.usersController});

  final UsersController usersController;

  final List<UserModel> list;
  final BuildContext context;

  @override
  DataRow? getRow(int index) {
    final user = list[index];
    return DataRow(
      onSelectChanged: (value) {
        showDialog(
            context: context,
            builder: (_) {
              return AlertDialogUser(usersController: usersController, user: user);
            });
      },
      cells: [
        DataCell(Text(user.id.toString())),
        DataCell(Text(user.name ?? '')),
        DataCell(Text(user.email ?? '')),
        DataCell(
          Container(
            margin: const EdgeInsets.only(left: 15),
            child: Tooltip(
              message: user.active! ? "Ativo" : "Inativo",
              child: Icon(
                LucideIcons.checkCircle2,
                size: 18,
                color: user.active! ? Colors.green : Colors.orange,
              ),
            ),
          ),
        ),
        DataCell(
          Text(user.type == 0
              ? 'Administrador'
              : user.type == 2
                  ? 'Associado'
                  : user.type == 1
                      ? 'Organização'
                      : ''),
        ),
        DataCell(Text(user.associates ?? '')),
        DataCell(Text(formatDate(user.createdAt!))),
      ],
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return Theme.of(context).hoverColor; // Cor ao passar o mouse
        }
        return null; // Cor padrão
      }),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => list.length;

  @override
  int get selectedRowCount => 0;
}
