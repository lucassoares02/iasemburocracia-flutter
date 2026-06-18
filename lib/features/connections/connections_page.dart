import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:toastification/toastification.dart';
import 'package:portal_assoc/features/companies/companies_controller.dart';
import 'package:portal_assoc/features/companies/companies_repository.dart';
import 'package:portal_assoc/features/companies/companies_usecase.dart';
import 'package:portal_assoc/features/connections/connections_model.dart';
import 'package:portal_assoc/features/connections/widgets/alert_dialog_connections.dart';
import 'package:portal_assoc/shared/widgets/loading_container.dart';
import '../../core/state/app_state.dart';
import '../companies/companies_model.dart';
import 'connections_controller.dart';
import 'connections_repository.dart';
import 'connections_usecase.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _DS {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s7 = 28.0;
  static const double rMd = 8.0;
  static const double rLg = 12.0;
  static const double rXl = 16.0;
  static const double rXxl = 20.0;
  static const double rFull = 9999.0;

  static const Color ink = Color(0xFF1C1C1E);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color stone = Color(0xFF8E91A0);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color successAccent = Color(0xFF00B473);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);
  static const Color successText = Color(0xFF15803D);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color waGreen = Color(0xFF25D366);
  static const Color waGreenSubtle = Color(0xFFDCFCE7);
}

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _statusColor(String? status) {
  switch (status) {
    case 'open':
      return _DS.successAccent;
    case 'connecting':
      return _DS.brandBlue;
    case 'close':
    case 'closed':
      return _DS.stone;
    default:
      return _DS.danger;
  }
}

Color _statusBg(String? status) {
  switch (status) {
    case 'open':
      return _DS.successSubtle;
    case 'connecting':
      return const Color(0xFFEEF2FF);
    case 'close':
    case 'closed':
      return _DS.surface;
    default:
      return _DS.dangerSubtle;
  }
}

Color _statusBorder(String? status) {
  switch (status) {
    case 'open':
      return _DS.successBorder;
    case 'connecting':
      return const Color(0xFFC7D2FE);
    case 'close':
    case 'closed':
      return _DS.hairline;
    default:
      return _DS.dangerBorder;
  }
}

String _statusLabel(String? status) {
  switch (status) {
    case 'open':
      return 'Conectado';
    case 'connecting':
      return 'Conectando';
    case 'close':
    case 'closed':
      return 'Desconectado';
    default:
      return status ?? 'Desconhecido';
  }
}

String _integrationLabel(String? integration) {
  switch (integration) {
    case 'WHATSAPP-BAILEYS':
      return 'WhatsApp Baileys';
    case 'WHATSAPP-BUSINESS':
      return 'WhatsApp Business';
    default:
      return integration ?? 'WhatsApp';
  }
}

IconData _integrationIcon(String? integration) {
  switch (integration) {
    case 'WHATSAPP-BAILEYS':
    case 'WHATSAPP-BUSINESS':
      return LucideIcons.messageCircle;
    default:
      return LucideIcons.zap;
  }
}

String _sanitizeInstanceName(String input) {
  const replacements = {
    'á': 'a',
    'à': 'a',
    'â': 'a',
    'ã': 'a',
    'ä': 'a',
    'é': 'e',
    'è': 'e',
    'ê': 'e',
    'ë': 'e',
    'í': 'i',
    'ì': 'i',
    'î': 'i',
    'ï': 'i',
    'ó': 'o',
    'ò': 'o',
    'ô': 'o',
    'õ': 'o',
    'ö': 'o',
    'ú': 'u',
    'ù': 'u',
    'û': 'u',
    'ü': 'u',
    'ç': 'c',
    'ñ': 'n',
  };
  var s = input.toLowerCase();
  for (final entry in replacements.entries) {
    s = s.replaceAll(entry.key, entry.value);
  }
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '-');
  s = s.replaceAll(RegExp(r'^-+|-+$'), '');
  return s;
}

// ─── Page ─────────────────────────────────────────────────────────────────────

class ConnectionsPage extends StatefulWidget {
  const ConnectionsPage({super.key});

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  late final ConnectionsController _ctrl = ConnectionsController(
    StartState(),
    ConnectionsUseCase(ConnectionsRepository()),
  );
  late final CompaniesController _companyCtrl = CompaniesController(
    StartState(),
    CompaniesUseCase(CompaniesRepository()),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.findAll();
    _companyCtrl.find();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        color: _DS.surface,
        padding: const EdgeInsets.all(_DS.s7),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: _DS.s6),
            Expanded(
              child: ValueListenableBuilder<StateApp>(
                valueListenable: _ctrl.stateFindAll,
                builder: (context, state, _) {
                  if (state is LoadingState) {
                    return _buildLoadingContent();
                  }
                  if (state is ErrorState) {
                    return _buildErrorState();
                  }
                  if (state is SuccessState) {
                    final connections = state.data as List<ConnectionsModel>;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _ConnectionsSummary(connections: connections),
                        const SizedBox(height: _DS.s5),
                        if (connections.isEmpty)
                          Expanded(child: _buildEmptyState())
                        else
                          Expanded(
                            child: ListView.separated(
                              itemCount: connections.length,
                              separatorBuilder: (_, __) => const SizedBox(height: _DS.s3),
                              itemBuilder: (_, i) => _ConnectionCard(
                                connection: connections[i],
                                controller: _ctrl,
                                onDeleted: _ctrl.findAll,
                                onReconnect: () {
                                  final cs = _companyCtrl.stateFind.value;
                                  if (cs is SuccessState) {
                                    _openQrDialog(cs.data as CompaniesModel, connections[i].instanceName!);
                                  }
                                },
                                onUpdateWorkflow: () => _handleUpdateWorkflow(connections[i]),
                              ),
                            ),
                          ),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Conexões',
                style: TextStyle(
                  fontSize: 20,
                  color: _DS.ink,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Gerencie integrações com canais externos',
                style: TextStyle(fontSize: 13, color: _DS.steel, height: 1.4),
              ),
            ],
          ),
        ),
        ValueListenableBuilder<StateApp>(
          valueListenable: _companyCtrl.stateFind,
          builder: (context, state, _) {
            if (state is! SuccessState) return const SizedBox.shrink();
            final company = state.data as CompaniesModel;
            return FilledButton.icon(
              onPressed: () => _createConnection(company),
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text('Nova conexão'),
              style: FilledButton.styleFrom(
                backgroundColor: _DS.ink,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  void _createConnection(CompaniesModel company) {
    final slug = _sanitizeInstanceName(company.name!);
    final state = _ctrl.stateFindAll.value;
    final existing = state is SuccessState ? (state.data as List<ConnectionsModel>).map((c) => c.instanceName ?? '').toList() : <String>[];
    showDialog(
      context: context,
      builder: (_) => AlertDialogConnections(
        controller: _ctrl,
        defaultInstanceName: slug,
        companyId: company.id!,
        existingInstanceNames: existing,
      ),
    );
  }

  void _openQrDialog(CompaniesModel company, String instanceName) {
    final state = _ctrl.stateFindAll.value;
    final existing = state is SuccessState ? (state.data as List<ConnectionsModel>).map((c) => c.instanceName ?? '').where((n) => n != instanceName).toList() : <String>[];
    showDialog(
      context: context,
      builder: (_) => AlertDialogConnections(
        controller: _ctrl,
        defaultInstanceName: instanceName,
        companyId: company.id!,
        existingInstanceNames: existing,
      ),
    );
  }

  Future<void> _handleUpdateWorkflow(ConnectionsModel conn) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _UpdateWorkflowConfirmDialog(instanceName: conn.instanceName ?? ''),
    );
    if (confirmed != true || !mounted) return;

    // Progress dialog + backend call em paralelo. Os estágios visuais avançam
    // sozinhos enquanto o n8n executa deactivate → delete → recreate → activate.
    final progress = ValueNotifier<int>(0);
    final stagesTimer = Timer.periodic(const Duration(milliseconds: 850), (t) {
      if (progress.value < 3) progress.value = progress.value + 1;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UpdateWorkflowProgressDialog(progress: progress),
    );

    final ok = await _ctrl.updateWorkflow(conn.id!);
    stagesTimer.cancel();
    if (!mounted) return;

    progress.value = 4; // marca todos como concluídos
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    Navigator.of(context, rootNavigator: true).pop(); // fecha progresso

    if (ok) {
      toastification.show(
        type: ToastificationType.success,
        style: ToastificationStyle.flat,
        title: const Text('Fluxo atualizado com sucesso 🚀'),
        description: const Text('O workflow foi recriado e está ativo.'),
        autoCloseDuration: const Duration(seconds: 3),
        animationDuration: const Duration(milliseconds: 300),
      );
    } else {
      toastification.show(
        type: ToastificationType.error,
        style: ToastificationStyle.flat,
        title: const Text('Não foi possível atualizar o fluxo'),
        description: const Text('Tente novamente em instantes.'),
        autoCloseDuration: const Duration(seconds: 4),
        animationDuration: const Duration(milliseconds: 300),
      );
    }
  }

  Widget _buildLoadingContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary skeleton
        Row(
          children: List.generate(
            4,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: i < 3 ? _DS.s3 : 0),
                child: const LoadingContainer(height: 72, width: double.maxFinite),
              ),
            ),
          ),
        ),
        const SizedBox(height: _DS.s5),
        ...List.generate(
          4,
          (_) => const Padding(
            padding: EdgeInsets.only(bottom: _DS.s3),
            child: LoadingContainer(height: 88, width: double.maxFinite),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.dangerSubtle,
              borderRadius: BorderRadius.circular(_DS.rXl),
            ),
            child: const Icon(LucideIcons.wifiOff, color: _DS.danger, size: 26),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Erro ao carregar conexões',
            style: TextStyle(fontSize: 16, color: _DS.ink),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tente novamente em alguns instantes.',
            style: TextStyle(fontSize: 14, color: _DS.steel),
          ),
          const SizedBox(height: _DS.s5),
          OutlinedButton.icon(
            onPressed: _ctrl.findAll,
            icon: const Icon(LucideIcons.refreshCw, size: 15),
            label: const Text('Tentar novamente'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _DS.ink,
              side: const BorderSide(color: _DS.hairline),
              shape: const StadiumBorder(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _DS.waGreenSubtle,
              borderRadius: BorderRadius.circular(_DS.rXxl),
            ),
            child: const Icon(LucideIcons.plugZap, size: 36, color: _DS.waGreen),
          ),
          const SizedBox(height: _DS.s5),
          const Text(
            'Conecte seu negócio com canais externos',
            style: TextStyle(
              fontSize: 17,
              color: _DS.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Integre WhatsApp, webhooks e outros canais\npara automatizar o atendimento.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: _DS.steel, height: 1.55),
          ),
          const SizedBox(height: _DS.s6),
          ValueListenableBuilder<StateApp>(
            valueListenable: _companyCtrl.stateFind,
            builder: (context, state, _) {
              if (state is! SuccessState) return const SizedBox.shrink();
              final company = state.data as CompaniesModel;
              return FilledButton.icon(
                onPressed: () => _createConnection(company),
                icon: const Icon(LucideIcons.plus, size: 16),
                label: const Text('Nova conexão'),
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  textStyle: const TextStyle(fontSize: 15),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Summary Strip ────────────────────────────────────────────────────────────

class _ConnectionsSummary extends StatelessWidget {
  const _ConnectionsSummary({required this.connections});

  final List<ConnectionsModel> connections;

  @override
  Widget build(BuildContext context) {
    final total = connections.length;
    final active = connections.where((c) => c.status == 'open').length;
    final errors = connections.where((c) => c.status != null && c.status != 'open' && c.status != 'connecting').length;
    final connecting = connections.where((c) => c.status == 'connecting').length;

    return Row(
      children: [
        Expanded(
          child: _SummaryTile(
            label: 'Total',
            value: '$total',
            icon: LucideIcons.link2,
            iconColor: _DS.slate,
            iconBg: _DS.hairlineSoft,
          ),
        ),
        const SizedBox(width: _DS.s3),
        Expanded(
          child: _SummaryTile(
            label: 'Ativas',
            value: '$active',
            icon: LucideIcons.checkCircle2,
            iconColor: _DS.successText,
            iconBg: _DS.successSubtle,
          ),
        ),
        const SizedBox(width: _DS.s3),
        Expanded(
          child: _SummaryTile(
            label: 'Conectando',
            value: '$connecting',
            icon: LucideIcons.loader,
            iconColor: _DS.brandBlue,
            iconBg: const Color(0xFFEEF2FF),
          ),
        ),
        const SizedBox(width: _DS.s3),
        Expanded(
          child: _SummaryTile(
            label: 'Com erro',
            value: '$errors',
            icon: LucideIcons.alertCircle,
            iconColor: _DS.danger,
            iconBg: _DS.dangerSubtle,
          ),
        ),
      ],
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: _DS.canvas,
        borderRadius: BorderRadius.circular(_DS.rXl),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(_DS.rLg)),
            child: Icon(icon, size: 17, color: iconColor),
          ),
          const SizedBox(width: _DS.s3),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  color: _DS.ink,
                  height: 1.1,
                ),
              ),
              Text(label, style: const TextStyle(fontSize: 11, color: _DS.stone)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Connection Card ──────────────────────────────────────────────────────────

class _ConnectionCard extends StatefulWidget {
  const _ConnectionCard({
    required this.connection,
    required this.controller,
    required this.onDeleted,
    required this.onReconnect,
    required this.onUpdateWorkflow,
  });

  final ConnectionsModel connection;
  final ConnectionsController controller;
  final VoidCallback onDeleted;
  final VoidCallback onReconnect;
  final VoidCallback onUpdateWorkflow;

  @override
  State<_ConnectionCard> createState() => _ConnectionCardState();
}

class _ConnectionCardState extends State<_ConnectionCard> {
  bool _hovered = false;
  bool _testing = false;
  bool? _testResult; // null = não testado
  bool _deleting = false;
  Timer? _resetTimer;

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleTest() async {
    if (_testing) return;
    setState(() {
      _testing = true;
      _testResult = null;
    });
    final ok = await widget.controller.testConnection(widget.connection.instanceName!);
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testResult = ok;
    });
    _resetTimer?.cancel();
    _resetTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _testResult = null);
    });
  }

  Future<void> _handleDelete() async {
    setState(() => _deleting = true);
    await widget.controller.delete(
      widget.connection.id!,
      widget.connection.instanceName!,
    );
    if (!mounted) return;
    setState(() => _deleting = false);
    widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final conn = widget.connection;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAFAFC) : _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(
            color: _hovered ? _DS.hairline : _DS.hairlineSoft,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
        child: Row(
          children: [
            // Icon
            _IntegrationIcon(integration: conn.integration),
            const SizedBox(width: _DS.s4),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          conn.instanceName ?? '—',
                          style: const TextStyle(
                            fontSize: 15,
                            color: _DS.ink,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: _DS.s2),
                      _IntegrationBadge(integration: conn.integration),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    conn.description?.isNotEmpty == true
                        ? conn.description!
                        : (conn.instanceId != null ? 'ID: ${conn.instanceId!.length > 22 ? '${conn.instanceId!.substring(0, 22)}…' : conn.instanceId}' : 'Sem descrição'),
                    style: const TextStyle(fontSize: 12, color: _DS.stone),
                  ),
                ],
              ),
            ),
            const SizedBox(width: _DS.s4),

            // Status + Actions
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _StatusBadge(status: conn.status),
                const SizedBox(height: _DS.s2),
                _ActionRow(
                  testing: _testing,
                  testResult: _testResult,
                  deleting: _deleting,
                  onTest: _handleTest,
                  onReconnect: widget.onReconnect,
                  onDelete: _handleDelete,
                  onUpdateWorkflow: widget.onUpdateWorkflow,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Integration Icon ─────────────────────────────────────────────────────────

class _IntegrationIcon extends StatelessWidget {
  const _IntegrationIcon({this.integration});
  final String? integration;

  @override
  Widget build(BuildContext context) {
    final isWa = integration == null || integration == 'WHATSAPP-BAILEYS' || integration == 'WHATSAPP-BUSINESS';
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isWa ? _DS.waGreenSubtle : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(_DS.rLg),
      ),
      child: Icon(
        _integrationIcon(integration),
        color: isWa ? _DS.waGreen : _DS.brandBlue,
        size: 22,
      ),
    );
  }
}

// ─── Integration Badge ────────────────────────────────────────────────────────

class _IntegrationBadge extends StatelessWidget {
  const _IntegrationBadge({this.integration});
  final String? integration;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s2, vertical: 3),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _DS.hairline),
      ),
      child: Text(
        _integrationLabel(integration),
        style: const TextStyle(
          fontSize: 10,
          color: _DS.slate,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

// ─── Status Badge ─────────────────────────────────────────────────────────────

class _StatusBadge extends StatefulWidget {
  const _StatusBadge({this.status});
  final String? status;

  @override
  State<_StatusBadge> createState() => _StatusBadgeState();
}

class _StatusBadgeState extends State<_StatusBadge> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _opacity = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.status == 'connecting') {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_StatusBadge old) {
    super.didUpdateWidget(old);
    if (widget.status == 'connecting') {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 1.0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = widget.status;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _statusBg(status),
        borderRadius: BorderRadius.circular(_DS.rFull),
        border: Border.all(color: _statusBorder(status)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: _opacity,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _statusColor(status),
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _statusLabel(status),
            style: TextStyle(
              fontSize: 11,
              color: _statusColor(status),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action Row ───────────────────────────────────────────────────────────────

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.testing,
    required this.testResult,
    required this.deleting,
    required this.onTest,
    required this.onReconnect,
    required this.onDelete,
    required this.onUpdateWorkflow,
  });

  final bool testing;
  final bool? testResult;
  final bool deleting;
  final VoidCallback onTest;
  final VoidCallback onReconnect;
  final VoidCallback onDelete;
  final VoidCallback onUpdateWorkflow;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Test result indicator
        if (testResult != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: testResult! ? _DS.successSubtle : _DS.dangerSubtle,
              borderRadius: BorderRadius.circular(_DS.rFull),
              border: Border.all(
                color: testResult! ? _DS.successBorder : _DS.dangerBorder,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  testResult! ? LucideIcons.checkCircle2 : LucideIcons.xCircle,
                  size: 11,
                  color: testResult! ? _DS.successText : _DS.danger,
                ),
                const SizedBox(width: 4),
                Text(
                  testResult! ? 'Online' : 'Offline',
                  style: TextStyle(
                    fontSize: 10,
                    color: testResult! ? _DS.successText : _DS.danger,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _DS.s2),
        ],

        // Test button
        _SmallButton(
          onPressed: onTest,
          loading: testing,
          icon: LucideIcons.activity,
          tooltip: 'Testar conexão',
          color: _DS.brandBlue,
          bgColor: const Color(0xFFEEF2FF),
        ),
        const SizedBox(width: _DS.s1),

        // Reconnect
        _SmallButton(
          onPressed: onReconnect,
          icon: LucideIcons.refreshCw,
          tooltip: 'Reconectar',
          color: _DS.slate,
          bgColor: _DS.surface,
        ),
        const SizedBox(width: _DS.s1),

        // Atualizar fluxo
        _SmallButton(
          onPressed: onUpdateWorkflow,
          icon: LucideIcons.workflow,
          tooltip: 'Atualizar fluxo',
          color: _DS.brandBlue,
          bgColor: const Color(0xFFEEF2FF),
        ),
        const SizedBox(width: _DS.s1),

        // Delete
        _SmallButton(
          onPressed: onDelete,
          loading: deleting,
          icon: LucideIcons.trash2,
          tooltip: 'Excluir',
          color: _DS.danger,
          bgColor: _DS.dangerSubtle,
        ),
      ],
    );
  }
}

class _SmallButton extends StatefulWidget {
  const _SmallButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    required this.color,
    required this.bgColor,
    this.loading = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final Color color;
  final Color bgColor;
  final bool loading;

  @override
  State<_SmallButton> createState() => _SmallButtonState();
}

class _SmallButtonState extends State<_SmallButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.loading ? null : widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? widget.bgColor : Colors.transparent,
              borderRadius: BorderRadius.circular(_DS.rMd),
            ),
            child: widget.loading
                ? Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: widget.color,
                      ),
                    ),
                  )
                : Icon(widget.icon, size: 15, color: widget.color),
          ),
        ),
      ),
    );
  }
}

// ─── Update workflow — confirm dialog ─────────────────────────────────────────

class _UpdateWorkflowConfirmDialog extends StatelessWidget {
  const _UpdateWorkflowConfirmDialog({required this.instanceName});

  final String instanceName;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxl)),
      backgroundColor: _DS.canvas,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(_DS.s6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(_DS.rLg),
                    ),
                    child: const Icon(LucideIcons.workflow, size: 20, color: _DS.brandBlue),
                  ),
                  const SizedBox(width: _DS.s3),
                  const Expanded(
                    child: Text(
                      'Atualizar fluxo do n8n',
                      style: TextStyle(fontSize: 16, color: _DS.ink, letterSpacing: -0.2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: _DS.s4),
              Text(
                'O workflow atual da conexão "$instanceName" será removido e '
                'recriado a partir do template mais recente. As configurações '
                'da empresa serão reaplicadas automaticamente.',
                style: const TextStyle(fontSize: 13.5, color: _DS.steel, height: 1.5),
              ),
              const SizedBox(height: _DS.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _DS.ink,
                      side: const BorderSide(color: _DS.hairline),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: _DS.s2),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(true),
                    icon: const Icon(LucideIcons.workflow, size: 15),
                    label: const Text('Atualizar fluxo'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DS.ink,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update workflow — progress dialog ────────────────────────────────────────

class _UpdateWorkflowProgressDialog extends StatelessWidget {
  const _UpdateWorkflowProgressDialog({required this.progress});

  /// 0..4 — quantos estágios já concluídos.
  final ValueNotifier<int> progress;

  static const List<String> _labels = [
    'Removendo workflow antigo',
    'Recriando fluxo',
    'Configurando automações',
    'Finalizando',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rXxl)),
      backgroundColor: _DS.canvas,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(_DS.s6),
          child: ValueListenableBuilder<int>(
            valueListenable: progress,
            builder: (_, step, __) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: _DS.brandBlue,
                        ),
                      ),
                      SizedBox(width: _DS.s3),
                      Text(
                        'Atualizando fluxo...',
                        style: TextStyle(fontSize: 15, color: _DS.ink, letterSpacing: -0.2),
                      ),
                    ],
                  ),
                  const SizedBox(height: _DS.s5),
                  for (int i = 0; i < _labels.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: _DS.s3),
                      child: Row(
                        children: [
                          _StageIcon(
                            done: step > i,
                            active: step == i,
                          ),
                          const SizedBox(width: _DS.s3),
                          Expanded(
                            child: Text(
                              _labels[i],
                              style: TextStyle(
                                fontSize: 13,
                                color: step > i ? _DS.successText : (step == i ? _DS.ink : _DS.stone),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _StageIcon extends StatelessWidget {
  const _StageIcon({required this.done, required this.active});
  final bool done;
  final bool active;

  @override
  Widget build(BuildContext context) {
    if (done) {
      return Container(
        width: 22,
        height: 22,
        decoration: const BoxDecoration(
          color: _DS.successSubtle,
          shape: BoxShape.circle,
        ),
        child: const Icon(LucideIcons.check, size: 13, color: _DS.successText),
      );
    }
    if (active) {
      return const SizedBox(
        width: 22,
        height: 22,
        child: Padding(
          padding: EdgeInsets.all(3),
          child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue),
        ),
      );
    }
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: _DS.surface,
        shape: BoxShape.circle,
        border: Border.all(color: _DS.hairline),
      ),
    );
  }
}
