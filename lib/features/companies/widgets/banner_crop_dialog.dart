import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Resolução de saída do banner (21:9).
const double kBannerOutW = 1680;
const double kBannerOutH = 720;
const double kBannerAspect = kBannerOutW / kBannerOutH;

/// Abre o editor de recorte 21:9 a partir dos bytes de uma imagem e devolve os
/// bytes PNG já recortados (1680×720), ou `null` se o usuário cancelar / a
/// imagem não puder ser decodificada.
Future<Uint8List?> showBannerCropDialog(BuildContext context, Uint8List bytes) async {
  final ui.Image image;
  try {
    final codec = await ui.instantiateImageCodec(bytes);
    image = (await codec.getNextFrame()).image;
  } catch (_) {
    return null;
  }
  if (!context.mounted) return null;
  return showDialog<Uint8List>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _BannerCropDialog(image: image),
  );
}

// ─── Editor de recorte do banner (21:9) ─────────────────────────────────────
// Permite posicionar (arrastar) e dar zoom na imagem dentro de um quadro 21:9;
// ao confirmar, recorta exatamente a área visível e devolve PNG em 1680×720.
class _BannerCropDialog extends StatefulWidget {
  final ui.Image image;
  const _BannerCropDialog({required this.image});

  @override
  State<_BannerCropDialog> createState() => _BannerCropDialogState();
}

class _BannerCropDialogState extends State<_BannerCropDialog> {
  static const _ink = Color(0xFF1C1C1E);
  static const double _maxZoom = 4;

  double _iw = 0, _ih = 0; // dimensões da imagem
  double _vw = 0, _vh = 0; // dimensões do viewport (quadro)
  double _baseScale = 1; // escala que "cobre" o viewport
  double _zoom = 1;
  Offset _offset = Offset.zero; // canto superior-esquerdo da imagem no viewport
  bool _initForWidth = false;
  double _lastWidth = 0;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _iw = widget.image.width.toDouble();
    _ih = widget.image.height.toDouble();
  }

  void _layout(double viewportWidth) {
    _vw = viewportWidth;
    _vh = viewportWidth / kBannerAspect;
    _baseScale = math.max(_vw / _iw, _vh / _ih);
    _zoom = 1;
    _offset = Offset((_vw - _iw * _baseScale) / 2, (_vh - _ih * _baseScale) / 2);
    _initForWidth = true;
    _lastWidth = viewportWidth;
  }

  double get _scale => _baseScale * _zoom;

  void _clamp() {
    final dispW = _iw * _scale;
    final dispH = _ih * _scale;
    final minX = _vw - dispW;
    final minY = _vh - dispH;
    _offset = Offset(
      _offset.dx.clamp(minX, 0.0),
      _offset.dy.clamp(minY, 0.0),
    );
  }

  void _onPan(DragUpdateDetails d) {
    setState(() {
      _offset += d.delta;
      _clamp();
    });
  }

  void _onZoom(double z) {
    setState(() {
      // Mantém o centro do viewport fixo ao dar zoom.
      final s0 = _scale;
      final cx = (_vw / 2 - _offset.dx) / s0;
      final cy = (_vh / 2 - _offset.dy) / s0;
      _zoom = z;
      final s1 = _scale;
      _offset = Offset(_vw / 2 - cx * s1, _vh / 2 - cy * s1);
      _clamp();
    });
  }

  Future<void> _confirm() async {
    setState(() => _processing = true);
    try {
      final s = _scale;
      final src = Rect.fromLTRB(
        -_offset.dx / s,
        -_offset.dy / s,
        (_vw - _offset.dx) / s,
        (_vh - _offset.dy) / s,
      );
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawImageRect(
        widget.image,
        src,
        const Rect.fromLTWH(0, 0, kBannerOutW, kBannerOutH),
        Paint()..filterQuality = FilterQuality.high,
      );
      final picture = recorder.endRecording();
      final img = await picture.toImage(kBannerOutW.toInt(), kBannerOutH.toInt());
      final data = await img.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(data?.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = math.min(screen.width * 0.9, 640.0);
    final viewportWidth = dialogWidth - 48; // padding interno

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: dialogWidth,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ajustar banner',
                  style: TextStyle(fontSize: 17, color: _ink, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                'Arraste para posicionar e use o controle para dar zoom. '
                'A imagem será recortada em ${kBannerOutW.toInt()} × ${kBannerOutH.toInt()} px (21:9).',
                style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B6F7E), height: 1.3),
              ),
              const SizedBox(height: 16),
              Builder(builder: (context) {
                if (!_initForWidth || _lastWidth != viewportWidth) {
                  _layout(viewportWidth);
                }
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: GestureDetector(
                      onPanUpdate: _onPan,
                      child: SizedBox(
                        width: _vw,
                        height: _vh,
                        child: CustomPaint(
                          painter: _CropPainter(image: widget.image, scale: _scale, offset: _offset),
                        ),
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(LucideIcons.zoomIn, size: 16, color: Color(0xFF6B6F7E)),
                  Expanded(
                    child: Slider(
                      value: _zoom,
                      min: 1,
                      max: _maxZoom,
                      activeColor: _ink,
                      onChanged: _processing ? null : _onZoom,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _processing ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF6B6F7E)),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _processing ? null : _confirm,
                    icon: _processing
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Icon(LucideIcons.check, size: 16),
                    label: const Text('Aplicar recorte'),
                    style: FilledButton.styleFrom(
                      backgroundColor: _ink,
                      foregroundColor: Colors.white,
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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

class _CropPainter extends CustomPainter {
  final ui.Image image;
  final double scale;
  final Offset offset;

  _CropPainter({required this.image, required this.scale, required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    canvas.drawColor(const Color(0xFFF1F2F4), BlendMode.src);
    final dst = Rect.fromLTWH(offset.dx, offset.dy, image.width * scale, image.height * scale);
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    canvas.drawImageRect(image, src, dst, Paint()..filterQuality = FilterQuality.medium);
  }

  @override
  bool shouldRepaint(_CropPainter old) => old.scale != scale || old.offset != offset || old.image != image;
}
