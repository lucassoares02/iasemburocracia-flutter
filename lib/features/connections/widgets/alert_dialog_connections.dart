import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:portal_assoc/core/state/app_state.dart';
import 'package:portal_assoc/features/connections/connections_controller.dart';
import 'package:portal_assoc/features/connections/connections_model.dart';
import 'package:portal_assoc/shared/extensions/context_screen_extension.dart';

// ─── Design Tokens ────────────────────────────────────────────────────────────

class _DS {
  static const Color ink = Color(0xFF1C1C1E);
  static const Color slate = Color(0xFF555A6A);
  static const Color steel = Color(0xFF6B6F7E);
  static const Color stone = Color(0xFF8E91A0);
  static const Color canvas = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF7F8FA);
  static const Color hairline = Color(0xFFE0E2E8);
  static const Color hairlineSoft = Color(0xFFEEF0F3);
  static const Color brandBlue = Color(0xFF4262FF);
  static const Color danger = Color(0xFFEF4444);
  static const Color dangerSubtle = Color(0xFFFEF2F2);
  static const Color waGreen = Color(0xFF25D366);
  static const Color waGreenSubtle = Color(0xFFDCFCE7);

  static const double rMd = 8.0;
  static const double rLg = 12.0;
  static const double rXl = 16.0;
  static const double rXxxl = 28.0;
  static const double rFull = 9999.0;

  static const double s2 = 8.0;
  static const double s3 = 12.0;
  static const double s4 = 16.0;
  static const double s5 = 20.0;
  static const double s6 = 24.0;
  static const double s7 = 28.0;
}

// ─── Step enum ────────────────────────────────────────────────────────────────

enum _Step { form, loading, qrCode, success, error }

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _randomDescription() {
  const opts = [
    'Canal principal de atendimento',
    'Suporte ao cliente via WhatsApp',
    'Canal de vendas automático',
    'Atendimento WhatsApp Business',
    'Integração de mensagens',
    'Canal de comunicação empresarial',
    'Atendimento e pedidos via WhatsApp',
  ];
  return opts[Random().nextInt(opts.length)];
}

// ─── Dialog ───────────────────────────────────────────────────────────────────

class AlertDialogConnections extends StatefulWidget {
  const AlertDialogConnections({
    super.key,
    required this.controller,
    required this.defaultInstanceName,
    required this.companyId,
    required this.existingInstanceNames,
  });

  final ConnectionsController controller;
  final String defaultInstanceName;
  final int companyId;
  final List<String> existingInstanceNames;

  @override
  State<AlertDialogConnections> createState() => _AlertDialogConnectionsState();
}

class _AlertDialogConnectionsState extends State<AlertDialogConnections> with TickerProviderStateMixin {
  _Step _step = _Step.form;
  String _instanceName = '';
  String? _errorMessage;
  bool _refreshing = false;
  Timer? _countdownTimer;
  Timer? _statusPollingTimer;
  final ValueNotifier<int> _countdownNotifier = ValueNotifier(25);
  final ValueNotifier<Uint8List?> _qrBytesNotifier = ValueNotifier(null);

  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _nameTouched = false;

  late final AnimationController _enterCtrl;
  late final Animation<double> _enterFade;
  late final Animation<double> _enterScale;
  late final AnimationController _successCtrl;
  late final Animation<double> _successScale;
  late final Animation<double> _successOpacity;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.defaultInstanceName);
    _descCtrl = TextEditingController();

    _enterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));
    _enterFade = CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOut);
    _enterScale = Tween<double>(begin: 0.94, end: 1.0).animate(CurvedAnimation(parent: _enterCtrl, curve: Curves.easeOutCubic));
    _enterCtrl.forward();

    _successCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _successScale = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _successCtrl, curve: Curves.elasticOut));
    _successOpacity = CurvedAnimation(parent: _successCtrl, curve: Curves.easeOut);

    widget.controller.stateCreate.addListener(_onCreateState);
    widget.controller.stateSocket.addListener(_onSocketState);
    widget.controller.qrCodeNotifier.addListener(_onQrCodeFromSocket);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    _countdownNotifier.dispose();
    _qrBytesNotifier.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _enterCtrl.dispose();
    _successCtrl.dispose();
    widget.controller.stateCreate.removeListener(_onCreateState);
    widget.controller.stateSocket.removeListener(_onSocketState);
    widget.controller.qrCodeNotifier.removeListener(_onQrCodeFromSocket);
    super.dispose();
  }

  // ── Listeners ──────────────────────────────────────────────────────────────

  void _onCreateState() {
    if (!mounted) return;
    final state = widget.controller.stateCreate.value;
    if (state is LoadingState) {
      setState(() => _step = _Step.loading);
    } else if (state is SuccessState) {
      String? rawQr;
      try {
        rawQr = state.data?.qrcode?.base64?.replaceAll('data:image/png;base64,', '');
      } catch (_) {}
      if (rawQr != null && rawQr.isNotEmpty) {
        _qrBytesNotifier.value = base64Decode(rawQr);
        setState(() => _step = _Step.qrCode);
        widget.controller.initSocket(_instanceName);
        _startCountdown();
        _startStatusPolling();
      } else {
        setState(() {
          _step = _Step.error;
          _errorMessage = 'QR Code não disponível. Tente novamente.';
        });
      }
    } else if (state is ErrorState) {
      setState(() {
        _step = _Step.error;
        _errorMessage = state.message;
      });
    }
  }

  void _onSocketState() {
    if (!mounted) return;
    if (widget.controller.stateSocket.value is SuccessState && _step == _Step.qrCode) {
      _handleSuccess();
    }
  }

  void _onQrCodeFromSocket() {
    if (!mounted || _step != _Step.qrCode) return;
    final qr = widget.controller.qrCodeNotifier.value;
    if (qr != null && qr.isNotEmpty) {
      _qrBytesNotifier.value = base64Decode(qr);
      _resetCountdown();
    }
  }

  void _handleSuccess() {
    _countdownTimer?.cancel();
    _statusPollingTimer?.cancel();
    widget.controller.findAll();
    if (mounted) {
      setState(() => _step = _Step.success);
      _successCtrl.forward();
    }
  }

  void _startStatusPolling() {
    _statusPollingTimer?.cancel();
    _statusPollingTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (!mounted || _step != _Step.qrCode) return;
      final connected = await widget.controller.isConnected(_instanceName);
      if (connected && mounted && _step == _Step.qrCode) {
        _handleSuccess();
      }
    });
  }

  // ── Countdown ──────────────────────────────────────────────────────────────

  void _startCountdown() {
    _countdownTimer?.cancel();
    if (!mounted) return;
    _countdownNotifier.value = 25;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      _countdownNotifier.value--;
      if (_countdownNotifier.value <= 0) {
        t.cancel();
        _refreshQrCode();
      }
    });
  }

  void _resetCountdown() {
    _countdownTimer?.cancel();
    _startCountdown();
  }

  Future<void> _refreshQrCode() async {
    if (!mounted || _step != _Step.qrCode) return;
    setState(() => _refreshing = true);
    final qr = await widget.controller.getQrCode(_instanceName);
    if (!mounted) return;
    if (qr == ConnectionsController.kConnected) {
      _handleSuccess();
      return;
    }
    if (qr != null && qr.isNotEmpty) {
      _qrBytesNotifier.value = base64Decode(qr);
    }
    setState(() => _refreshing = false);
    _startCountdown();
  }

  // ── Form ────────────────────────────────────────────────────────────────────

  void _submit() {
    setState(() => _nameTouched = true);
    if (!_formKey.currentState!.validate()) return;
    _instanceName = _nameCtrl.text.trim();
    final desc = _descCtrl.text.trim().isEmpty ? _randomDescription() : _descCtrl.text.trim();
    widget.controller.create(
      ConnectionsModel.fromJson({
        'instanceName': _instanceName,
        'description': desc,
        'integration': 'WHATSAPP-BAILEYS',
        'qrcode': true,
        'company': widget.companyId,
      }),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final maxH = context.screenHeight < 800 ? context.screenHeight * 0.90 : context.screenHeight * 0.82;
    final maxW = context.screenWidth < 1200
        ? context.screenWidth * 0.88
        : context.screenWidth < 1600
            ? context.screenWidth * 0.50
            : 680.0;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: FadeTransition(
        opacity: _enterFade,
        child: ScaleTransition(
          scale: _enterScale,
          child: Container(
            width: maxW,
            constraints: BoxConstraints(maxHeight: maxH),
            decoration: BoxDecoration(
              color: _DS.canvas,
              borderRadius: BorderRadius.circular(_DS.rXxxl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 48,
                  offset: const Offset(0, 20),
                  spreadRadius: -4,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_DS.rXxxl),
              child: _buildStep(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case _Step.form:
        return _buildForm();
      case _Step.loading:
        return _buildLoading();
      case _Step.qrCode:
        return _buildQrCode();
      case _Step.success:
        return _buildSuccess();
      case _Step.error:
        return _buildError();
    }
  }

  // ─── Step: Form ──────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          icon: LucideIcons.plugZap,
          iconBg: _DS.waGreenSubtle,
          iconColor: _DS.waGreen,
          title: 'Nova conexão WhatsApp',
          subtitle: 'Configure antes de conectar',
          onClose: () => Navigator.pop(context),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(_DS.s7, _DS.s5, _DS.s7, _DS.s7),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _FieldLabel(text: 'Nome da instância', required: true),
                  const SizedBox(height: _DS.s2),
                  TextFormField(
                    controller: _nameCtrl,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_\-]')),
                      LengthLimitingTextInputFormatter(50),
                    ],
                    onChanged: (_) {
                      if (_nameTouched) _formKey.currentState?.validate();
                    },
                    style: const TextStyle(fontSize: 14, color: _DS.ink),
                    decoration: _inputDec(
                      hint: 'ex: minha_empresa_wa',
                      helper: 'Letras, números, _ ou – sem espaços',
                    ),
                    validator: (v) {
                      final val = v?.trim() ?? '';
                      if (val.isEmpty) return 'Informe um nome para a instância';
                      if (val.length < 3) return 'Mínimo de 3 caracteres';
                      if (widget.existingInstanceNames.map((n) => n.toLowerCase()).contains(val.toLowerCase())) {
                        return 'Já existe uma conexão com esse nome';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: _DS.s5),
                  const _FieldLabel(text: 'Descrição'),
                  const SizedBox(height: _DS.s2),
                  TextFormField(
                    controller: _descCtrl,
                    maxLength: 120,
                    style: const TextStyle(fontSize: 14, color: _DS.ink),
                    decoration: _inputDec(
                      hint: 'ex: Canal de atendimento principal',
                      helper: 'Opcional — gerada automaticamente se vazio',
                    ),
                  ),
                  const SizedBox(height: _DS.s4),
                  Container(
                    padding: const EdgeInsets.all(_DS.s3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(_DS.rLg),
                      border: Border.all(color: const Color(0xFFC7D2FE)),
                    ),
                    child: const Row(
                      children: [
                        Icon(LucideIcons.info, size: 13, color: _DS.brandBlue),
                        SizedBox(width: _DS.s2),
                        Expanded(
                          child: Text(
                            'Após criar, um QR Code será exibido para vincular o WhatsApp.',
                            style: TextStyle(fontSize: 12, color: _DS.brandBlue, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: _DS.s6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _DS.ink,
                          side: const BorderSide(color: _DS.hairline),
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: _DS.s3),
                      FilledButton.icon(
                        onPressed: _submit,
                        icon: const Icon(LucideIcons.arrowRight, size: 15),
                        label: const Text('Criar conexão'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _DS.ink,
                          foregroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          textStyle: const TextStyle(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step: Loading ────────────────────────────────────────────────────────────

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: _DS.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: _DS.waGreenSubtle,
              borderRadius: BorderRadius.circular(_DS.rXl),
            ),
            child: const Padding(
              padding: EdgeInsets.all(14),
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _DS.waGreen),
            ),
          ),
          const SizedBox(height: _DS.s5),
          const Text(
            'Criando conexão…',
            style: TextStyle(fontSize: 17, color: _DS.ink, letterSpacing: -0.3),
          ),
          const SizedBox(height: 6),
          const Text(
            'Configurando instância e workflow de automação.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _DS.steel, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ─── Step: QR Code ────────────────────────────────────────────────────────────

  Widget _buildQrCode() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Header(
          icon: Icons.qr_code_rounded,
          iconBg: _DS.waGreenSubtle,
          iconColor: _DS.waGreen,
          title: 'Conectar WhatsApp',
          subtitle: 'Escaneie o QR Code com seu celular',
          onClose: () => Navigator.pop(context),
        ),
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(_DS.s7),
            child: Column(
              children: [
                // QR + countdown ring — each updates independently via ValueListenableBuilder
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ValueListenableBuilder<int>(
                      valueListenable: _countdownNotifier,
                      builder: (_, count, __) => SizedBox(
                        width: 240,
                        height: 240,
                        child: CircularProgressIndicator(
                          value: count / 25,
                          strokeWidth: 3,
                          backgroundColor: _DS.hairlineSoft,
                          color: count <= 5 ? _DS.danger : _DS.waGreen,
                        ),
                      ),
                    ),
                    Container(
                      width: 218,
                      height: 218,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(_DS.rXl),
                        border: Border.all(color: _DS.hairlineSoft, width: 1.5),
                      ),
                      child: ValueListenableBuilder<Uint8List?>(
                        valueListenable: _qrBytesNotifier,
                        builder: (_, bytes, __) {
                          if (_refreshing) {
                            return const Center(
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: _DS.waGreen),
                            );
                          }
                          if (bytes != null) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(bytes, fit: BoxFit.contain),
                            );
                          }
                          return const Center(
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: _DS.waGreen),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: _DS.s3),

                // Countdown text + refresh button — isolated from image rebuilds
                ValueListenableBuilder<int>(
                  valueListenable: _countdownNotifier,
                  builder: (_, count, __) => Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.clock, size: 12, color: count <= 5 ? _DS.danger : _DS.stone),
                      const SizedBox(width: 5),
                      Text(
                        'Atualiza em ${count}s',
                        style: TextStyle(
                          fontSize: 12,
                          color: count <= 5 ? _DS.danger : _DS.stone,
                        ),
                      ),
                      const SizedBox(width: _DS.s2),
                      GestureDetector(
                        onTap: _refreshing ? null : _refreshQrCode,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _DS.surface,
                            borderRadius: BorderRadius.circular(_DS.rFull),
                            border: Border.all(color: _DS.hairline),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(LucideIcons.refreshCw, size: 10, color: _refreshing ? _DS.stone : _DS.slate),
                              const SizedBox(width: 4),
                              Text(
                                'Atualizar',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _refreshing ? _DS.stone : _DS.slate,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: _DS.s6),

                const _StepRow(number: '1', icon: LucideIcons.smartphone, text: 'Abra o WhatsApp no celular'),
                const SizedBox(height: _DS.s2),
                const _StepRow(number: '2', icon: LucideIcons.monitor, text: 'Toque em Dispositivos conectados'),
                const SizedBox(height: _DS.s2),
                const _StepRow(number: '3', icon: LucideIcons.scanLine, text: 'Aponte a câmera para o QR Code'),

                const SizedBox(height: _DS.s5),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        color: _DS.steel.withValues(alpha: 0.6),
                      ),
                    ),
                    const SizedBox(width: _DS.s2),
                    const Text(
                      'Aguardando leitura do QR Code…',
                      style: TextStyle(
                        fontSize: 12,
                        color: _DS.stone,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── Step: Success ────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: _DS.s7),
      child: ScaleTransition(
        scale: _successScale,
        child: FadeTransition(
          opacity: _successOpacity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      _DS.waGreen.withValues(alpha: 0.15),
                      _DS.waGreen.withValues(alpha: 0.03),
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Container(
                  margin: const EdgeInsets.all(14),
                  decoration: const BoxDecoration(color: _DS.waGreen, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
                ),
              ),
              const SizedBox(height: _DS.s6),
              const Text(
                'Conectado com sucesso!',
                style: TextStyle(fontSize: 20, color: _DS.ink, letterSpacing: -0.4),
              ),
              const SizedBox(height: _DS.s2),
              const Text(
                'Sua conta do WhatsApp foi vinculada\ne está pronta para uso.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _DS.steel, height: 1.6),
              ),
              const SizedBox(height: _DS.s7),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.waGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(fontSize: 15),
                  ),
                  child: const Text('Concluir'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Step: Error ──────────────────────────────────────────────────────────────

  Widget _buildError() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 56, horizontal: _DS.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(color: _DS.dangerSubtle, borderRadius: BorderRadius.circular(_DS.rXl)),
            child: const Icon(LucideIcons.xCircle, color: _DS.danger, size: 28),
          ),
          const SizedBox(height: _DS.s5),
          const Text(
            'Erro ao criar conexão',
            style: TextStyle(fontSize: 17, color: _DS.ink),
          ),
          const SizedBox(height: _DS.s2),
          Text(
            _errorMessage ?? 'Ocorreu um erro inesperado. Tente novamente.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: _DS.steel, height: 1.5),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: _DS.s6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _DS.ink,
                  side: const BorderSide(color: _DS.hairline),
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Fechar'),
              ),
              const SizedBox(width: _DS.s3),
              FilledButton(
                onPressed: () => setState(() {
                  _step = _Step.form;
                  _errorMessage = null;
                }),
                style: FilledButton.styleFrom(
                  backgroundColor: _DS.ink,
                  foregroundColor: Colors.white,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Input decoration ─────────────────────────────────────────────────────────

  InputDecoration _inputDec({required String hint, String? helper}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: _DS.stone),
      helperText: helper,
      helperStyle: const TextStyle(fontSize: 11, color: _DS.steel),
      helperMaxLines: 2,
      filled: true,
      fillColor: _DS.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.rMd),
        borderSide: const BorderSide(color: _DS.hairline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.rMd),
        borderSide: const BorderSide(color: _DS.hairline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.rMd),
        borderSide: const BorderSide(color: _DS.brandBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.rMd),
        borderSide: const BorderSide(color: _DS.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(_DS.rMd),
        borderSide: const BorderSide(color: _DS.danger, width: 1.5),
      ),
    );
  }
}

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onClose,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(_DS.s7, _DS.s6, _DS.s5, _DS.s5),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _DS.hairlineSoft)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(_DS.rLg)),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: _DS.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 15, color: _DS.ink, letterSpacing: -0.2),
                ),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: _DS.stone)),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 18, color: _DS.stone),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_DS.rMd)),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.text, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(text, style: const TextStyle(fontSize: 13, color: _DS.slate)),
        if (required) ...[
          const SizedBox(width: 3),
          const Text('*',
              style: TextStyle(
                fontSize: 13,
                color: _DS.danger,
              )),
        ],
      ],
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.icon, required this.text});
  final String number;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: _DS.s4, vertical: _DS.s3),
      decoration: BoxDecoration(
        color: _DS.surface,
        borderRadius: BorderRadius.circular(_DS.rLg),
        border: Border.all(color: _DS.hairlineSoft),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(_DS.rMd),
            ),
            child: Text(
              number,
              style: const TextStyle(fontSize: 12, color: _DS.brandBlue),
            ),
          ),
          const SizedBox(width: _DS.s3),
          Icon(icon, size: 15, color: _DS.stone),
          const SizedBox(width: _DS.s2),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                  fontSize: 13,
                  color: _DS.ink,
                )),
          ),
        ],
      ),
    );
  }
}
