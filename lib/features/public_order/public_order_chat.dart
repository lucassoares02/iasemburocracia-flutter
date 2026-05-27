part of 'public_order_page.dart';

void _openOrderChat(
  BuildContext context, {
  required int orderId,
  required String phone,
  required String clientName,
  required Color brandColor,
  required String companyName,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OrderChatSheet(
      orderId: orderId,
      phone: phone,
      clientName: clientName,
      brandColor: brandColor,
      companyName: companyName,
    ),
  );
}

// ─── Bottom sheet ─────────────────────────────────────────────────────────────

class _OrderChatSheet extends StatefulWidget {
  final int orderId;
  final String phone;
  final String clientName;
  final Color brandColor;
  final String companyName;

  const _OrderChatSheet({
    required this.orderId,
    required this.phone,
    required this.clientName,
    required this.brandColor,
    required this.companyName,
  });

  @override
  State<_OrderChatSheet> createState() => _OrderChatSheetState();
}

class _OrderChatSheetState extends State<_OrderChatSheet> {
  final _repo = PublicOrderRepository();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<OrderMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _load(silent: true),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final res = await _repo.getOrderMessages(widget.orderId, widget.phone);
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _messages = (res.data as List).map((e) => OrderMessageModel.fromJson(e as Map<String, dynamic>)).toList();
          _loading = false;
          _error = null;
        });
        _scrollToBottom();
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients && _scrollCtrl.position.hasContentDimensions) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    final backup = text;
    _inputCtrl.clear();
    setState(() => _sending = true);
    try {
      final res = await _repo.sendPublicMessage(
        widget.orderId,
        widget.phone,
        text,
        senderName: widget.clientName,
      );
      if (!mounted) return;
      if (res.success) {
        await _load(silent: true);
      } else {
        _inputCtrl.text = backup;
      }
    } catch (_) {
      if (mounted) _inputCtrl.text = backup;
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 640,
          maxHeight: MediaQuery.sizeOf(context).height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: _DS.canvas,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 2),
                decoration: BoxDecoration(
                  color: _DS.hairline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.brandColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: widget.brandColor,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chat — Pedido #${widget.orderId}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: _DS.ink,
                          ),
                        ),
                        Text(
                          widget.companyName,
                          style: const TextStyle(fontSize: 12, color: _DS.steel),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20, color: _DS.stone),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(color: _DS.hairlineSoft, height: 1),
            Flexible(
              child: _loading && _messages.isEmpty
                  ? _buildSkeleton()
                  : _error != null && _messages.isEmpty
                      ? _buildError()
                      : _messages.isEmpty
                          ? _buildEmpty()
                          : ListView.builder(
                              controller: _scrollCtrl,
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                              itemCount: _messages.length,
                              itemBuilder: (_, i) {
                                final msg = _messages[i];
                                return _ChatBubble(
                                  message: msg,
                                  isRight: msg.senderType == 'customer',
                                  rightColor: widget.brandColor,
                                  leftFallbackName: 'Loja',
                                );
                              },
                            ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(12, 8, 12, 12 + bottomInset),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      maxLines: 4,
                      minLines: 1,
                      maxLength: 2000,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: 'Escreva uma mensagem...',
                        hintStyle: const TextStyle(color: _DS.muted, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: _DS.hairline),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: widget.brandColor, width: 2),
                        ),
                        filled: true,
                        fillColor: _DS.surface,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        counterText: '',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: widget.brandColor,
                      disabledBackgroundColor: widget.brandColor.withValues(alpha: 0.4),
                      shape: const CircleBorder(),
                      padding: const EdgeInsets.all(13),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, size: 18, color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimBox(200, 40, rightAlign: false),
          const SizedBox(height: 10),
          _shimBox(140, 40, rightAlign: true),
          const SizedBox(height: 10),
          _shimBox(260, 40, rightAlign: false),
          const SizedBox(height: 10),
          _shimBox(180, 40, rightAlign: true),
        ],
      ),
    );
  }

  Widget _shimBox(double width, double height, {required bool rightAlign}) {
    return Align(
      alignment: rightAlign ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: _DS.hairlineSoft,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 36, color: _DS.stone),
          const SizedBox(height: 12),
          const Text(
            'Não foi possível carregar o chat',
            style: TextStyle(fontSize: 14, color: _DS.steel),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _load,
            style: OutlinedButton.styleFrom(
              foregroundColor: _DS.ink,
              side: const BorderSide(color: _DS.hairline),
              shape: const StadiumBorder(),
            ),
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 40, color: _DS.stone),
          SizedBox(height: 12),
          Text(
            'Sem mensagens ainda',
            style: TextStyle(fontSize: 15, color: _DS.ink),
          ),
          SizedBox(height: 4),
          Text(
            'Envie uma mensagem para a loja',
            style: TextStyle(fontSize: 13, color: _DS.steel),
          ),
        ],
      ),
    );
  }
}

// ─── Chat bubble ──────────────────────────────────────────────────────────────

class _ChatBubble extends StatelessWidget {
  final OrderMessageModel message;
  final bool isRight;
  final Color rightColor;
  final String leftFallbackName;

  const _ChatBubble({
    required this.message,
    required this.isRight,
    required this.rightColor,
    this.leftFallbackName = 'Loja',
  });

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt != null ? DateFormat('HH:mm', 'pt_BR').format(message.createdAt!.toLocal()) : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12,
        left: isRight ? 48 : 0,
        right: isRight ? 0 : 48,
      ),
      child: Align(
        alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: isRight ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isRight) ...[
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 3),
                child: Text(
                  message.senderName ?? leftFallbackName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.stone,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isRight ? rightColor : _DS.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isRight ? 16 : 4),
                  bottomRight: Radius.circular(isRight ? 4 : 16),
                ),
                border: isRight ? null : Border.all(color: _DS.hairlineSoft),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 14,
                  color: isRight ? Colors.white : _DS.ink,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(
                time,
                style: const TextStyle(fontSize: 10, color: _DS.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
