part of 'public_order_page.dart';

// ─── Success screen ───────────────────────────────────────────────────────────
class _SuccessScreen extends StatelessWidget {
  final int orderId;
  final String companyName;
  final Color brandColor;
  final DateTime? scheduledFor;
  final VoidCallback onNewOrder;
  const _SuccessScreen({
    required this.orderId,
    required this.companyName,
    required this.brandColor,
    required this.scheduledFor,
    required this.onNewOrder,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
                child: const Icon(Icons.check_rounded, size: 44, color: Color(0xFF065F46)),
              ),
              const SizedBox(height: 24),
              const Text('Pedido enviado!', style: TextStyle(fontSize: 24, color: _DS.ink)),
              const SizedBox(height: 8),
              Text(
                'Pedido #$orderId recebido por $companyName.\nVocê será avisado sobre o status.',
                style: const TextStyle(fontSize: 14, color: _DS.steel, height: 1.5),
                textAlign: TextAlign.center,
              ),
              if (scheduledFor != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: brandColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(_DS.rXl),
                    border: Border.all(color: brandColor.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.event_rounded, size: 18, color: brandColor),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Agendado para',
                              style: TextStyle(
                                fontSize: 11,
                                color: brandColor.withValues(alpha: 0.75),
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _scheduleLabel(scheduledFor!, full: true),
                              style: TextStyle(
                                fontSize: 14,
                                color: brandColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onNewOrder,
                  style: FilledButton.styleFrom(
                    backgroundColor: brandColor,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Fazer novo pedido',
                      style: TextStyle(
                        fontSize: 16,
                      )),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
