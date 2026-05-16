import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/features/company_opening_hours/company_opening_hours_model.dart';
import 'package:portal_assoc/shared/widgets/special_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/state/app_state.dart';
import 'company_opening_hours_controller.dart';
import 'company_opening_hours_repository.dart';
import 'company_opening_hours_usecase.dart';

// ─── Design Tokens ──────────────────────────────────────────────────────────

class _DS {
  static const double s1 = 4.0;
  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s8 = 32.0;

  static const double radiusSm = 6.0;
  static const double radiusMd = 10.0;
  static const double radiusLg = 14.0;

  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7F7F8);
  static const Color border = Color(0xFFE4E4E7);
  static const Color borderStrong = Color(0xFFD4D4D8);
  static const Color borderFocus = Color(0xFF18181B);
  static const Color textPrimary = Color(0xFF09090B);
  static const Color textSecondary = Color(0xFF71717A);
  static const Color textTertiary = Color(0xFFA1A1AA);
  static const Color accent = Color(0xFF18181B);
  static const Color accentSubtle = Color(0xFFF4F4F5);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color success = Color(0xFF22C55E);
  static const Color successSubtle = Color(0xFFF0FDF4);
  static const Color successBorder = Color(0xFFBBF7D0);

  static List<BoxShadow> shadowSm = [
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1)),
    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 1),
  ];

  static List<BoxShadow> shadowMd = [
    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 24, offset: const Offset(0, 8)),
    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6, offset: const Offset(0, 2)),
  ];
}

// ─── Page ────────────────────────────────────────────────────────────────────

class CompanyOpeningHoursPage extends StatefulWidget {
  const CompanyOpeningHoursPage({super.key});

  @override
  State<CompanyOpeningHoursPage> createState() => _CompanyOpeningHoursPageState();
}

class _CompanyOpeningHoursPageState extends State<CompanyOpeningHoursPage> with SingleTickerProviderStateMixin {
  late final CompanyOpeningHoursController controller = CompanyOpeningHoursController(
    StartState(),
    CompanyOpeningHoursUseCase(CompanyOpeningHoursRepository()),
  );

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final Map<int, String> weekdayNames = {
    1: 'Segunda-feira',
    2: 'Terça-feira',
    3: 'Quarta-feira',
    4: 'Quinta-feira',
    5: 'Sexta-feira',
    6: 'Sábado',
    7: 'Domingo',
  };

  static const Map<int, String> _weekdayAbbr = {
    1: 'SEG',
    2: 'TER',
    3: 'QUA',
    4: 'QUI',
    5: 'SEX',
    6: 'SÁB',
    7: 'DOM',
  };

  @override
  void initState() {
    super.initState();
    controller.findAll();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // ─── Helpers ───────────────────────────────────────────────────────────────

  TimeOfDay _parseTimeOfDay(String time) {
    final parts = time.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  String _formatTimeOfDay(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  // ─── Dialog ────────────────────────────────────────────────────────────────

  void _showAddEditDialog({CompanyOpeningHoursModel? existingHours}) {
    final formKey = GlobalKey<FormState>();
    int selectedWeekday = existingHours?.weekday ?? 1;
    bool isClosed = existingHours?.isClosed ?? false;
    TimeOfDay opensAt = existingHours?.opensAt != null ? _parseTimeOfDay(existingHours!.opensAt!) : const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay closesAt = existingHours?.closesAt != null ? _parseTimeOfDay(existingHours!.closesAt!) : const TimeOfDay(hour: 18, minute: 0);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            width: 480,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusLg + 2),
              border: Border.all(color: _DS.border),
              boxShadow: _DS.shadowMd,
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(_DS.s8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dialog header
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                existingHours == null ? 'Novo Horário' : 'Editar Horário',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: _DS.textPrimary,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: _DS.s1),
                              Text(
                                existingHours == null ? 'Configure o horário para um dia da semana.' : 'Atualize os dados do horário selecionado.',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: _DS.textSecondary,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _DialogCloseButton(onPressed: () => Navigator.pop(context)),
                      ],
                    ),

                    const SizedBox(height: _DS.s6),
                    const _DialogDivider(),
                    const SizedBox(height: _DS.s6),

                    // Weekday picker
                    _DialogFieldLabel(label: 'Dia da Semana', icon: LucideIcons.calendar),
                    const SizedBox(height: _DS.s2),
                    _SaasDropdown<int>(
                      value: selectedWeekday,
                      items: weekdayNames.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                      onChanged: (v) => setDialogState(() => selectedWeekday = v!),
                    ),

                    const SizedBox(height: _DS.s5),

                    // Closed toggle
                    _ClosedToggleRow(
                      isClosed: isClosed,
                      onChanged: (v) => setDialogState(() => isClosed = v),
                    ),

                    // Time pickers (animated)
                    AnimatedSize(
                      duration: const Duration(milliseconds: 220),
                      curve: Curves.easeInOut,
                      child: isClosed
                          ? const SizedBox.shrink()
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: _DS.s5),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _DialogFieldLabel(label: 'Abertura', icon: LucideIcons.sunrise),
                                          const SizedBox(height: _DS.s2),
                                          _TimePickerButton(
                                            time: opensAt,
                                            onTap: () async {
                                              final picked = await _pickTime(context, opensAt);
                                              if (picked != null) setDialogState(() => opensAt = picked);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: _DS.s3),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          _DialogFieldLabel(label: 'Fechamento', icon: LucideIcons.sunset),
                                          const SizedBox(height: _DS.s2),
                                          _TimePickerButton(
                                            time: closesAt,
                                            onTap: () async {
                                              final picked = await _pickTime(context, closesAt);
                                              if (picked != null) setDialogState(() => closesAt = picked);
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                    ),

                    const SizedBox(height: _DS.s6),
                    const _DialogDivider(),
                    const SizedBox(height: _DS.s5),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _SaasGhostButton(
                          label: 'Cancelar',
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(width: _DS.s2),
                        ValueListenableBuilder(
                          valueListenable: controller.stateCreate,
                          builder: (context, value, _) => SpecialButton(
                            label: "Salvar",
                            loading: value is LoadingState,
                            error: value is ErrorState,
                            color: _DS.accent,
                            icon: LucideIcons.check,
                            onPressButton: () async {
                              final prefs = await SharedPreferences.getInstance();
                              final company = prefs.getInt('company') ?? 0;
                              if (formKey.currentState!.validate()) {
                                final newHours = CompanyOpeningHoursModel.fromJson({
                                  existingHours != null ? "id" : "": existingHours?.id,
                                  "weekday": selectedWeekday,
                                  "company_id": company,
                                  "opens_at": isClosed ? null : _formatTimeOfDay(opensAt),
                                  "closes_at": isClosed ? null : _formatTimeOfDay(closesAt),
                                  "is_closed": isClosed,
                                });
                                existingHours == null ? controller.create(newHours) : controller.update(newHours);
                                Navigator.pop(context);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<TimeOfDay?> _pickTime(BuildContext context, TimeOfDay initial) {
    return showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          timePickerTheme: TimePickerThemeData(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
        child: child!,
      ),
    );
  }

  // ─── Delete Dialog ─────────────────────────────────────────────────────────

  void _showDeleteConfirmation(CompanyOpeningHoursModel hours) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(_DS.s6),
          decoration: BoxDecoration(
            color: _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusLg + 2),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowMd,
          ),
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
                      color: _DS.dangerSubtle,
                      borderRadius: BorderRadius.circular(_DS.radiusMd),
                      border: Border.all(color: _DS.dangerBorder),
                    ),
                    child: const Icon(LucideIcons.trash2, size: 16, color: _DS.danger),
                  ),
                  const SizedBox(width: _DS.s3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Excluir Horário',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: _DS.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          weekdayNames[hours.weekday] ?? '',
                          style: const TextStyle(
                            fontSize: 12,
                            color: _DS.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _DialogCloseButton(onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: _DS.s5),
              Container(
                padding: const EdgeInsets.all(_DS.s4),
                decoration: BoxDecoration(
                  color: _DS.background,
                  borderRadius: BorderRadius.circular(_DS.radiusMd),
                  border: Border.all(color: _DS.border),
                ),
                child: Text(
                  'Esta ação não pode ser desfeita. O horário de ${weekdayNames[hours.weekday]} será removido permanentemente.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: _DS.textSecondary,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: _DS.s5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _SaasGhostButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: _DS.s2),
                  _SaasDangerButton(
                    label: 'Excluir',
                    onPressed: () {
                      controller.delete(hours.id!);
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPageHeader(),
            Expanded(
              child: ValueListenableBuilder(
                valueListenable: controller.stateFindAll,
                builder: (context, state, _) {
                  if (state is StartState || state is LoadingState) {
                    return _buildLoadingSkeleton();
                  } else if (state is SuccessState) {
                    final List<CompanyOpeningHoursModel> hours = List<CompanyOpeningHoursModel>.from(state.data);
                    hours.sort((CompanyOpeningHoursModel a, CompanyOpeningHoursModel b) => (a.weekday ?? 0).compareTo(b.weekday ?? 0));
                    if (hours.isEmpty) return _buildEmptyState();
                    return _buildList(hours);
                  } else if (state is ErrorState) {
                    return _buildErrorState(state.message);
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

  // ─── Page Header ───────────────────────────────────────────────────────────

  Widget _buildPageHeader() {
    return Container(
      color: _DS.surface,
      padding: const EdgeInsets.symmetric(horizontal: _DS.s6, vertical: _DS.s5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Horários de Funcionamento',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _DS.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: _DS.s1),
                const Text(
                  'Configure os dias e horários de atendimento da sua empresa.',
                  style: TextStyle(
                    fontSize: 13,
                    color: _DS.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: _DS.s4),
          _SaasPrimaryButton(
            label: 'Novo Horário',
            icon: LucideIcons.plus,
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
    );
  }

  // ─── List ──────────────────────────────────────────────────────────────────

  Widget _buildList(List<CompanyOpeningHoursModel> items) {
    return ScrollConfiguration(
      behavior: const ScrollBehavior().copyWith(scrollbars: false),
      child: ListView.builder(
        padding: const EdgeInsets.all(_DS.s6),
        itemCount: items.length,
        itemBuilder: (context, index) {
          return _HoursListItem(
            hours: items[index],
            weekdayName: weekdayNames[items[index].weekday] ?? '—',
            abbreviation: _weekdayAbbr[items[index].weekday] ?? '---',
            onEdit: () => _showAddEditDialog(existingHours: items[index]),
            onDelete: () => _showDeleteConfirmation(items[index]),
          );
        },
      ),
    );
  }

  // ─── Empty State ───────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.accentSubtle,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.border),
            ),
            child: const Icon(LucideIcons.clock, size: 24, color: _DS.textSecondary),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Nenhum horário cadastrado',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _DS.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _DS.s2),
          const Text(
            'Adicione os horários de funcionamento da sua empresa.',
            style: TextStyle(fontSize: 13, color: _DS.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _DS.s6),
          _SaasOutlinedButton(
            label: 'Adicionar Horário',
            icon: LucideIcons.plus,
            onPressed: () => _showAddEditDialog(),
          ),
        ],
      ),
    );
  }

  // ─── Loading Skeleton ──────────────────────────────────────────────────────

  Widget _buildLoadingSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(_DS.s6),
      child: Column(
        children: List.generate(
          5,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: _DS.s3),
            height: 72,
            decoration: BoxDecoration(
              color: _DS.surface,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: _DS.s5),
                _SkeletonBox(width: 40, height: 40, radius: _DS.radiusMd),
                const SizedBox(width: _DS.s4),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SkeletonBox(width: 140, height: 14, radius: 4),
                      const SizedBox(height: _DS.s2),
                      _SkeletonBox(width: 100, height: 11, radius: 4),
                    ],
                  ),
                ),
                _SkeletonBox(width: 60, height: 24, radius: 20),
                const SizedBox(width: _DS.s4),
                _SkeletonBox(width: 32, height: 32, radius: _DS.radiusMd),
                const SizedBox(width: _DS.s2),
                _SkeletonBox(width: 32, height: 32, radius: _DS.radiusMd),
                const SizedBox(width: _DS.s4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Error State ───────────────────────────────────────────────────────────

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.dangerSubtle,
              borderRadius: BorderRadius.circular(_DS.radiusLg),
              border: Border.all(color: _DS.dangerBorder),
            ),
            child: const Icon(LucideIcons.alertTriangle, size: 24, color: _DS.danger),
          ),
          const SizedBox(height: _DS.s4),
          const Text(
            'Erro ao carregar horários',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: _DS.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: _DS.textSecondary, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: _DS.s6),
          _SaasOutlinedButton(
            label: 'Tentar novamente',
            icon: LucideIcons.refreshCw,
            onPressed: () => controller.findAll(),
          ),
        ],
      ),
    );
  }
}

// ─── List Item ───────────────────────────────────────────────────────────────

class _HoursListItem extends StatefulWidget {
  const _HoursListItem({
    required this.hours,
    required this.weekdayName,
    required this.abbreviation,
    required this.onEdit,
    required this.onDelete,
  });

  final CompanyOpeningHoursModel hours;
  final String weekdayName;
  final String abbreviation;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_HoursListItem> createState() => _HoursListItemState();
}

class _HoursListItemState extends State<_HoursListItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isClosed = widget.hours.isClosed ?? false;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.only(bottom: _DS.s3),
        decoration: BoxDecoration(
          color: _hovered ? const Color(0xFFFAFAFB) : _DS.surface,
          borderRadius: BorderRadius.circular(_DS.radiusLg),
          border: Border.all(color: _hovered ? _DS.borderStrong : _DS.border),
          boxShadow: _hovered ? _DS.shadowSm : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _DS.s5, vertical: _DS.s4),
          child: Row(
            children: [
              // Day chip
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _DS.accentSubtle,
                  borderRadius: BorderRadius.circular(_DS.radiusMd),
                ),
                child: Center(
                  child: Text(
                    widget.abbreviation,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _DS.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: _DS.s4),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.weekdayName,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _DS.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: _DS.s1 + 2),
                    isClosed
                        ? const Text(
                            'Não funciona neste dia',
                            style: TextStyle(fontSize: 12, color: _DS.textTertiary),
                          )
                        : Row(
                            children: [
                              const Icon(LucideIcons.arrowRight, size: 12, color: _DS.textTertiary),
                              const SizedBox(width: _DS.s1),
                              Text(
                                '${widget.hours.opensAt?.substring(0, 5) ?? '--:--'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _DS.textSecondary,
                                ),
                              ),
                              const Padding(
                                padding: EdgeInsets.symmetric(horizontal: _DS.s2),
                                child: Text('→', style: TextStyle(fontSize: 11, color: _DS.textTertiary)),
                              ),
                              Text(
                                '${widget.hours.closesAt?.substring(0, 5) ?? '--:--'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _DS.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),
              // Status badge
              _StatusBadge(isOpen: !isClosed),
              const SizedBox(width: _DS.s4),
              // Actions
              _IconActionButton(
                icon: LucideIcons.pencil,
                onPressed: widget.onEdit,
                tooltip: 'Editar',
              ),
              const SizedBox(width: _DS.s2),
              _IconActionButton(
                icon: LucideIcons.trash2,
                onPressed: widget.onDelete,
                tooltip: 'Excluir',
                isDanger: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Dialog Components ────────────────────────────────────────────────

class _DialogFieldLabel extends StatelessWidget {
  const _DialogFieldLabel({required this.label, required this.icon});
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 13, color: _DS.textTertiary),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _DS.textSecondary,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

class _DialogDivider extends StatelessWidget {
  const _DialogDivider();
  @override
  Widget build(BuildContext context) => const Divider(height: 1, thickness: 1, color: Color(0xFFF1F1F2));
}

class _DialogCloseButton extends StatefulWidget {
  const _DialogCloseButton({required this.onPressed});
  final VoidCallback onPressed;
  @override
  State<_DialogCloseButton> createState() => _DialogCloseButtonState();
}

class _DialogCloseButtonState extends State<_DialogCloseButton> {
  bool _hovered = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.radiusSm),
          ),
          child: const Icon(LucideIcons.x, size: 15, color: _DS.textSecondary),
        ),
      ),
    );
  }
}

class _ClosedToggleRow extends StatelessWidget {
  const _ClosedToggleRow({required this.isClosed, required this.onChanged});
  final bool isClosed;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: isClosed ? _DS.dangerSubtle : _DS.accentSubtle,
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        border: Border.all(color: isClosed ? _DS.dangerBorder : _DS.border),
      ),
      child: Row(
        children: [
          Icon(
            isClosed ? LucideIcons.xCircle : LucideIcons.checkCircle,
            size: 16,
            color: isClosed ? _DS.danger : _DS.success,
          ),
          const SizedBox(width: _DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fechado neste dia',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _DS.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isClosed ? 'Estabelecimento não funciona neste dia' : 'Estabelecimento funciona neste dia',
                  style: const TextStyle(fontSize: 11, color: _DS.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isClosed,
            onChanged: onChanged,
            activeColor: _DS.danger,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

class _SaasDropdown<T> extends StatelessWidget {
  const _SaasDropdown({
    required this.value,
    required this.items,
    required this.onChanged,
  });
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusSm),
        border: Border.all(color: _DS.border),
        boxShadow: _DS.shadowSm,
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        items: items,
        onChanged: onChanged,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: _DS.textPrimary,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s3),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        dropdownColor: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.radiusMd),
        icon: const Icon(LucideIcons.chevronsUpDown, size: 14, color: _DS.textTertiary),
      ),
    );
  }
}

class _TimePickerButton extends StatefulWidget {
  const _TimePickerButton({required this.time, required this.onTap});
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  State<_TimePickerButton> createState() => _TimePickerButtonState();
}

class _TimePickerButtonState extends State<_TimePickerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hour = widget.time.hour.toString().padLeft(2, '0');
    final minute = widget.time.minute.toString().padLeft(2, '0');

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: _DS.s3),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusSm),
            border: Border.all(color: _hovered ? _DS.borderStrong : _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            children: [
              const Icon(LucideIcons.clock, size: 14, color: _DS.textTertiary),
              const SizedBox(width: _DS.s2),
              Text(
                '$hour:$minute',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: _DS.textPrimary,
                  letterSpacing: 0.5,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const Spacer(),
              const Icon(LucideIcons.chevronsUpDown, size: 12, color: _DS.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared Button Components ────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isOpen});
  final bool isOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen ? _DS.successSubtle : _DS.dangerSubtle,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOpen ? _DS.successBorder : _DS.dangerBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: isOpen ? _DS.success : _DS.danger,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            isOpen ? 'Aberto' : 'Fechado',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOpen ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconActionButton extends StatefulWidget {
  const _IconActionButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
    this.isDanger = false,
  });
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final bool isDanger;

  @override
  State<_IconActionButton> createState() => _IconActionButtonState();
}

class _IconActionButtonState extends State<_IconActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hoverBg = widget.isDanger ? _DS.dangerSubtle : _DS.accentSubtle;
    final hoverColor = widget.isDanger ? _DS.danger : _DS.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onPressed,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _hovered ? hoverBg : Colors.transparent,
              borderRadius: BorderRadius.circular(_DS.radiusSm),
              border: Border.all(
                color: _hovered ? (widget.isDanger ? _DS.dangerBorder : _DS.border) : Colors.transparent,
              ),
            ),
            child: Icon(
              widget.icon,
              size: 14,
              color: _hovered ? hoverColor : _DS.textTertiary,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaasPrimaryButton extends StatefulWidget {
  const _SaasPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_SaasPrimaryButton> createState() => _SaasPrimaryButtonState();
}

class _SaasPrimaryButtonState extends State<_SaasPrimaryButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFF27272A) : _DS.accent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: Colors.white),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaasOutlinedButton extends StatefulWidget {
  const _SaasOutlinedButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  State<_SaasOutlinedButton> createState() => _SaasOutlinedButtonState();
}

class _SaasOutlinedButtonState extends State<_SaasOutlinedButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : _DS.surface,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            border: Border.all(color: _DS.border),
            boxShadow: _DS.shadowSm,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.icon, size: 14, color: _DS.textSecondary),
              const SizedBox(width: _DS.s2),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _DS.textPrimary,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaasGhostButton extends StatefulWidget {
  const _SaasGhostButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SaasGhostButton> createState() => _SaasGhostButtonState();
}

class _SaasGhostButtonState extends State<_SaasGhostButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s3, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? _DS.accentSubtle : Colors.transparent,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
          ),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _hovered ? _DS.textPrimary : _DS.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SaasDangerButton extends StatefulWidget {
  const _SaasDangerButton({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;

  @override
  State<_SaasDangerButton> createState() => _SaasDangerButtonState();
}

class _SaasDangerButtonState extends State<_SaasDangerButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? const Color(0xFFDC2626) : _DS.danger,
            borderRadius: BorderRadius.circular(_DS.radiusMd),
            boxShadow: _DS.shadowSm,
          ),
          child: Text(
            widget.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: -0.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  const _SkeletonBox({required this.width, required this.height, this.radius = 4});
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFF1F1F2),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
