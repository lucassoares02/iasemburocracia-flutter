import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Validação e feedback de upload de imagens (banners/logos).
///
/// Limite alinhado ao backend: os uploads passam pelo multer com
/// `limits: { fileSize: 10 * 1024 * 1024 }` (10 MB) — ver
/// `api/controllers/companiessssController.js`. Validamos ANTES de enviar para
/// evitar o erro 413 (Request Entity Too Large) e dar feedback claro.
const int kMaxImageUploadBytes = 10 * 1024 * 1024;

/// Extensões aceitas pelos uploads de imagem da plataforma.
const List<String> kAllowedImageExtensions = ['jpg', 'jpeg', 'png', 'webp'];

// Tokens locais (padrão visual do projeto).
class _DS {
  static const ink = Color(0xFF1C1C1E);
  static const canvas = Color(0xFFFFFFFF);
  static const surface = Color(0xFFF7F8FA);
  static const hairline = Color(0xFFE0E2E8);
  static const steel = Color(0xFF6B6F7E);
  static const stone = Color(0xFF8E91A0);
  static const danger = Color(0xFFE53935);
  static const dangerSubtle = Color(0xFFFEF2F2);
  static const successAccent = Color(0xFF00B473);
}

/// Formata bytes em rótulo humano pt-BR (ex.: "5,8 MB", "320 KB").
String formatFileSize(int bytes) {
  if (bytes >= 1024 * 1024) {
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} MB';
  }
  if (bytes >= 1024) return '${(bytes / 1024).round()} KB';
  return '$bytes B';
}

/// Resultado da validação preventiva de um arquivo de imagem.
class UploadValidationResult {
  final String? title;
  final String? message;
  final int? fileBytes;

  const UploadValidationResult.ok()
      : title = null,
        message = null,
        fileBytes = null;

  const UploadValidationResult.error(this.title, this.message, {this.fileBytes});

  bool get ok => title == null;
}

/// Valida o arquivo selecionado ANTES de qualquer upload:
/// arquivo vazio, extensão não suportada e tamanho acima do limite.
UploadValidationResult validateImageUpload(PlatformFile file, {int maxBytes = kMaxImageUploadBytes}) {
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    return const UploadValidationResult.error(
      'Arquivo vazio',
      'O arquivo selecionado está vazio ou não pôde ser lido. Tente outra imagem.',
    );
  }
  final ext = (file.extension ?? '').toLowerCase();
  if (ext.isNotEmpty && !kAllowedImageExtensions.contains(ext)) {
    return UploadValidationResult.error(
      'Formato não suportado',
      'O formato ".$ext" não é aceito. Use JPG, JPEG, PNG ou WEBP.',
    );
  }
  if (bytes.lengthInBytes > maxBytes) {
    return UploadValidationResult.error(
      'Imagem muito grande',
      'A imagem selecionada possui ${formatFileSize(bytes.lengthInBytes)}. '
          'O tamanho máximo permitido é ${formatFileSize(maxBytes)}. '
          'Escolha uma imagem menor para continuar.',
      fileBytes: bytes.lengthInBytes,
    );
  }
  return const UploadValidationResult.ok();
}

/// Dialog compacto e elegante para erros de upload (sem stacktrace/termos
/// técnicos). Quando `fileBytes` é informado, mostra o comparativo
/// "Imagem selecionada × Limite permitido".
Future<void> showUploadErrorDialog(
  BuildContext context, {
  required String title,
  required String message,
  int? fileBytes,
  int limitBytes = kMaxImageUploadBytes,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.45),
    builder: (ctx) => Dialog(
      backgroundColor: _DS.canvas,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _DS.dangerSubtle,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(LucideIcons.imageOff, size: 20, color: _DS.danger),
              ),
              const SizedBox(height: 14),
              Text(title, style: const TextStyle(fontSize: 17, color: _DS.ink, letterSpacing: -0.3)),
              const SizedBox(height: 6),
              Text(message, style: const TextStyle(fontSize: 13, color: _DS.steel, height: 1.5)),
              if (fileBytes != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _DS.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _DS.hairline),
                  ),
                  child: Column(
                    children: [
                      _sizeRow('Imagem selecionada', formatFileSize(fileBytes), _DS.danger),
                      const SizedBox(height: 6),
                      _sizeRow('Limite permitido', formatFileSize(limitBytes), _DS.ink),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: FilledButton.styleFrom(
                    backgroundColor: _DS.ink,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                  child: const Text('Escolher outra imagem'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _sizeRow(String label, String value, Color valueColor) {
  return Row(
    children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5, color: _DS.steel))),
      Text(value, style: TextStyle(fontSize: 12.5, color: valueColor, fontWeight: FontWeight.w600)),
    ],
  );
}

/// Linha discreta de requisitos exibida junto às áreas de upload:
/// formatos aceitos, limite de tamanho e resolução recomendada.
class UploadHints extends StatelessWidget {
  final String? recommendation;
  const UploadHints({super.key, this.recommendation});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const _Hint(icon: LucideIcons.check, text: 'JPG, PNG ou WEBP', iconColor: _DS.successAccent),
        _Hint(icon: LucideIcons.hardDrive, text: 'Até ${formatFileSize(kMaxImageUploadBytes)}'),
        if (recommendation != null) _Hint(icon: LucideIcons.scaling, text: recommendation!),
      ],
    );
  }
}

class _Hint extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color iconColor;
  const _Hint({required this.icon, required this.text, this.iconColor = _DS.stone});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 11, color: iconColor),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 11, color: _DS.stone)),
      ],
    );
  }
}
