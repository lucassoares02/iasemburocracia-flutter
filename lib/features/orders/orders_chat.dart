part of 'orders_page.dart';

// ─── Admin order chat tab ─────────────────────────────────────────────────────

class _AdminOrderChat extends StatefulWidget {
  final int orderId;
  final String clientName;
  final VoidCallback? onMessagesRead;

  const _AdminOrderChat({
    required this.orderId,
    required this.clientName,
    this.onMessagesRead,
  });

  @override
  State<_AdminOrderChat> createState() => _AdminOrderChatState();
}

class _AdminOrderChatState extends State<_AdminOrderChat> {
  final _repo = OrdersRepository();
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  List<OrderMessageModel> _messages = [];
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _pollTimer;
  bool _readCalled = false;

  @override
  void initState() {
    super.initState();
    _load();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 10),
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
      final res = await _repo.getOrderMessages(widget.orderId);
      if (!mounted) return;
      if (res.success && res.data is List) {
        setState(() {
          _messages = (res.data as List).map((e) => OrderMessageModel.fromJson(e as Map<String, dynamic>)).toList();
          _loading = false;
          _error = null;
        });
        _scrollToBottom();
        if (!_readCalled) {
          _readCalled = true;
          _repo.markOrderMessagesRead(widget.orderId).ignore();
          widget.onMessagesRead?.call();
        }
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
      final res = await _repo.sendAdminMessage(widget.orderId, text);
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
    if (_loading && _messages.isEmpty) return _buildSkeleton();
    if (_error != null && _messages.isEmpty) return _buildError();

    return Column(
      children: [
        Expanded(
          child: _messages.isEmpty
              ? _buildEmpty()
              : ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                  itemCount: _messages.length,
                  itemBuilder: (_, i) {
                    final msg = _messages[i];
                    return _AdminChatBubble(
                      message: msg,
                      isRight: msg.senderType == 'company',
                    );
                  },
                ),
        ),
        const Divider(color: _DS.hairlineSoft, height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _inputCtrl,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 2000,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Responder ao cliente...',
                    hintStyle: TextStyle(color: _DS.muted, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _DS.hairline),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _DS.hairline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: _DS.brandBlue, width: 2),
                    ),
                    filled: true,
                    fillColor: _DS.surface,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _sending ? null : _send,
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.brandBlue,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: _sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 16, color: Colors.white),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return const Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2, color: _DS.brandBlue),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_rounded, size: 32, color: _DS.stone),
          const SizedBox(height: 10),
          const Text(
            'Erro ao carregar mensagens',
            style: TextStyle(fontSize: 13, color: _DS.steel),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: _load,
            child: const Text('Tentar novamente', style: TextStyle(color: _DS.brandBlue)),
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
          Icon(Icons.chat_bubble_outline_rounded, size: 32, color: _DS.stone),
          SizedBox(height: 10),
          Text(
            'Sem mensagens',
            style: TextStyle(fontSize: 14, color: _DS.ink),
          ),
          SizedBox(height: 4),
          Text(
            'O cliente ainda não enviou mensagens',
            style: TextStyle(fontSize: 12, color: _DS.steel),
          ),
        ],
      ),
    );
  }
}

// ─── Admin chat bubble ────────────────────────────────────────────────────────

class _AdminChatBubble extends StatelessWidget {
  final OrderMessageModel message;
  final bool isRight;

  const _AdminChatBubble({
    required this.message,
    required this.isRight,
  });

  @override
  Widget build(BuildContext context) {
    final time = message.createdAt != null ? DateFormat('HH:mm', 'pt_BR').format(message.createdAt!.toLocal()) : '';

    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
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
                  message.senderName ?? 'Cliente',
                  style: const TextStyle(
                    fontSize: 11,
                    color: _DS.stone,
                  ),
                ),
              ),
            ],
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: isRight ? _DS.brandBlue : _DS.surface,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isRight ? 14 : 4),
                  bottomRight: Radius.circular(isRight ? 4 : 14),
                ),
                border: isRight ? null : Border.all(color: _DS.hairlineSoft),
              ),
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 13,
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
