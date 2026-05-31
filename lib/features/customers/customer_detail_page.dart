part of 'customers_page.dart';

// ─── Standalone Detail Page (route: /customers/:id) ──────────────────────────
class CustomerDetailPage extends StatefulWidget {
  final int id;
  const CustomerDetailPage({super.key, required this.id});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  late final CustomersController _ctrl = CustomersController(
    CustomersUseCase(CustomersRepository()),
  );

  @override
  void initState() {
    super.initState();
    _ctrl.fetchDetails(widget.id);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _goBack() => context.goNamed('customers');

  void _openEdit(CustomerModel c) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _CustomerFormModal(ctrl: _ctrl, customer: c),
    );
  }

  Future<void> _confirmDelete(CustomerModel c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => _DeleteConfirmDialog(name: c.name),
    );
    if (confirmed != true || !mounted) return;
    final res = await _ctrl.deleteCustomer(widget.id);
    if (res.success && mounted) _goBack();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _DS.surface,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<StateApp>(
                  valueListenable: _ctrl.stateDetails,
                  builder: (_, state, __) {
                    String? name;
                    if (state is SuccessState && state.data is CustomerModel) {
                      name = (state.data as CustomerModel).name;
                    }
                    return _DetailBreadcrumb(
                      customerName: name,
                      onBack: _goBack,
                    );
                  },
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ValueListenableBuilder<StateApp>(
                    valueListenable: _ctrl.stateDetails,
                    builder: (_, state, __) {
                      if (state is LoadingState || state is StartState) {
                        return const _DetailSkeleton();
                      }
                      if (state is ErrorState) {
                        return _DetailErrorState(message: state.message);
                      }
                      if (state is SuccessState && state.data is CustomerModel) {
                        final c = state.data as CustomerModel;
                        return _DetailContent(
                          customer: c,
                          onEdit: () => _openEdit(c),
                          onDelete: () => _confirmDelete(c),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Breadcrumb / Back Header ────────────────────────────────────────────────
class _DetailBreadcrumb extends StatelessWidget {
  final String? customerName;
  final VoidCallback onBack;
  const _DetailBreadcrumb({required this.customerName, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _BackButton(onTap: onBack),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _BreadcrumbTrail(name: customerName, onBack: onBack),
              const SizedBox(height: 2),
              Text(
                customerName ?? 'Carregando…',
                style: const TextStyle(
                  fontSize: 22,
                  color: _DS.ink,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BreadcrumbTrail extends StatefulWidget {
  final String? name;
  final VoidCallback onBack;
  const _BreadcrumbTrail({required this.name, required this.onBack});

  @override
  State<_BreadcrumbTrail> createState() => _BreadcrumbTrailState();
}

class _BreadcrumbTrailState extends State<_BreadcrumbTrail> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTap: widget.onBack,
            child: Text(
              'Clientes',
              style: TextStyle(
                fontSize: 12,
                color: _hover ? _DS.brandBlue : _DS.stone,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 6),
          child: Icon(Icons.chevron_right_rounded, size: 14, color: _DS.muted),
        ),
        Flexible(
          child: Text(
            widget.name ?? '—',
            style: const TextStyle(fontSize: 12, color: _DS.steel),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _BackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _BackButton({required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Voltar para a lista',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _hover ? _DS.surface : _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rFull),
              border: Border.all(color: _DS.hairline),
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.arrow_back_rounded, size: 17, color: _DS.slate),
          ),
        ),
      ),
    );
  }
}

// ─── Error state (used by detail page) ────────────────────────────────────────
class _DetailErrorState extends StatelessWidget {
  final String message;
  const _DetailErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.circular(_DS.rXl),
          border: Border.all(color: _DS.hairlineSoft),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 36, color: _DS.danger),
            const SizedBox(height: 10),
            const Text(
              'Erro ao carregar cliente',
              style: TextStyle(fontSize: 15, color: _DS.ink, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: const TextStyle(fontSize: 12, color: _DS.stone),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
