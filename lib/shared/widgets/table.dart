import 'package:flutter/material.dart';

class AppTable extends StatefulWidget {
  const AppTable({super.key, required this.columns, required this.dataSourceTable, this.rowsPerPage = 5, this.title});

  final List<DataColumn> columns;
  final DataTableSource dataSourceTable;
  final int rowsPerPage;
  final Widget? title;

  @override
  State<AppTable> createState() => _AppTableState();
}

class _AppTableState extends State<AppTable> {
  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: Theme.of(context).colorScheme.surface,
            ),
      ),
      child: DataTableTheme(
        data: const DataTableThemeData(
          dividerThickness: 0.2,
          decoration: BoxDecoration(
            color: Colors.transparent,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: PaginatedDataTable(
            headingRowHeight: 56,
            showFirstLastButtons: true,
            showCheckboxColumn: false,
            header: widget.title,
            columns: widget.columns,
            rowsPerPage: widget.rowsPerPage,
            source: widget.dataSourceTable,
          ),
        ),
      ),
    );
  }
}
