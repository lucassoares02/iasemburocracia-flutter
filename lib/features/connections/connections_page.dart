import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/companies_usecase.dart';
import 'package:portal_assoc/features/connections/connections_model.dart';
import 'package:portal_assoc/features/connections/widgets/alert_dialog_connections.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';
import '../../core/state/app_state.dart';
import '../companies/companies_model.dart';
import 'connections_controller.dart';
import 'connections_repository.dart';
import 'connections_usecase.dart';

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  late final ConnectionsController controller = ConnectionsController(StartState(), ConnectionsUseCase(ConnectionsRepository()));
  late final CompaniesController companiesController = CompaniesController(StartState(), CompaniesUseCase(CompaniesRepository()));

  @override
  void initState() {
    controller.findAll();
    companiesController.find();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Conexões",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: colors.onSurface,
                            letterSpacing: -0.5,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "Gerencie suas integrações com WhatsApp",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
                ValueListenableBuilder(
                  valueListenable: companiesController.stateFind,
                  builder: (context, value, child) {
                    if (value is LoadingState) {
                      return const LoadingContainer(width: 150, height: 40);
                    }
                    if (value is ErrorState) {
                      return const SizedBox.shrink();
                    }
                    if (value is SuccessState) {
                      CompaniesModel company = value.data;
                      return SpecialButton(
                        icon: Icons.add_rounded,
                        color: colors.primary,
                        label: "Nova Conexão",
                        onPressButton: () {
                          controller.create(
                            ConnectionsModel.fromJson({
                              "description": "Integração WhatsApp Baileys",
                              "instanceName": company.name!.toLowerCase().replaceAll(" ", "_"),
                              "integration": "WHATSAPP-BAILEYS",
                              "qrcode": true,
                              "company": company.id,
                            }),
                          );
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialogConnections(
                              controller: controller,
                              instance: company.name!.toLowerCase().replaceAll(" ", "_"),
                            ),
                          );
                        },
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Connections list
            ValueListenableBuilder(
              valueListenable: controller.stateFindAll,
              builder: (context, value, child) {
                if (value is LoadingState) {
                  return _buildSkeletonList();
                }
                if (value is ErrorState) {
                  return _buildErrorState(context, colors);
                }
                if (value is SuccessState) {
                  List<ConnectionsModel> connections = value.data;
                  if (connections.isEmpty) {
                    return _buildEmptyState(context, colors);
                  }
                  return Expanded(
                    child: ListView.separated(
                      itemCount: connections.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return _ConnectionCard(
                          connection: connections[index],
                          colors: colors,
                          controller: controller,
                        );
                      },
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonList() {
    return Expanded(
      child: ListView.separated(
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, __) => const LoadingContainer(
          width: double.maxFinite,
          height: 80,
        ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, ColorScheme colors) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: colors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline_rounded, color: colors.onErrorContainer, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              "Erro ao carregar conexões",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              "Tente novamente em alguns instantes.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colors) {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.wifi_tethering_rounded,
                size: 34,
                color: colors.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Nenhuma conexão encontrada",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              "Crie uma nova conexão para começar.",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({
    required this.connection,
    required this.colors,
    required this.controller,
  });

  final ConnectionsModel connection;
  final ColorScheme colors;
  final ConnectionsController controller;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState(controller: controller);
}

class _ConnectionCardState extends State<_ConnectionCard> {
  _ConnectionCardState({required this.controller});

  final ConnectionsController controller;

  bool _hovered = false;

  String _integrationLabel(String? integration) {
    switch (integration) {
      case 'WHATSAPP-BAILEYS':
        return 'WhatsApp Baileys';
      case 'WHATSAPP-BUSINESS':
        return 'WhatsApp Business';
      default:
        return integration ?? 'Integrado';
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = widget.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: _hovered ? colors.surfaceContainerHighest.withOpacity(0.5) : colors.surfaceContainerHighest.withOpacity(0.25),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? colors.outlineVariant.withOpacity(0.7) : colors.outlineVariant.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: _hovered
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.messageCircle,
                color: Color(0xFF25D366),
                size: 22,
              ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.connection.instanceName ?? "Sem nome de instância",
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colors.onSurface,
                          letterSpacing: -0.2,
                        ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    widget.connection.description ?? "Sem descrição",
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Badge
            Row(
              children: [
                IconButton(
                  onPressed: () async {
                    await widget.controller.delete(widget.connection.id!, widget.connection.instanceName!);
                    widget.controller.findAll();
                  },
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: Color(0xFF25D366),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _integrationLabel(widget.connection.integration),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
