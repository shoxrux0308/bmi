import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart';
import '../providers/auth_provider.dart';
import '../providers/auth_provider.dart' show AnalysisProvider;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _navIndex = 0;
  bool _enhance = false;
  String _mode = 'auto';
  bool _isDragging = false;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf', 'docx'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final path = kIsWeb ? null : file.path;
    if (path == null && file.bytes == null) return;
    await _analyze(path, file.bytes, file.name, _getMimeType(file.extension));
  }

  Future<void> _pickFromCamera() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (image == null) return;
    final bytes = await image.readAsBytes();
    await _analyze(image.path, bytes, 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg', 'image/jpeg');
  }

  String _getMimeType(String? ext) {
    switch (ext?.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:    return 'image/jpeg';
    }
  }

  Future<void> _analyze(String? path, Uint8List? bytes, String name, String mime) async {
    final provider = context.read<AnalysisProvider>();
    final ok = await provider.uploadFile(
      filePath: path, fileBytes: bytes, fileName: name, mimeType: mime,
      enhance: _enhance, mode: _mode,
    );
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamed(context, '/result');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Xatolik'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final analysis = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 32, height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                gradient: const LinearGradient(
                    colors: [Color(0xFF6C63FF), Color(0xFF3D5AFE)]),
              ),
              child: const Icon(Icons.document_scanner_rounded, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Text('BMI OCR+NLP'),
          ],
        ),
        actions: [
          if (auth.isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings_outlined),
              onPressed: () => Navigator.pushNamed(context, '/admin'),
            ),
          IconButton(
            icon: const Icon(Icons.history_rounded),
            onPressed: () => Navigator.pushNamed(context, '/history'),
          ),
          IconButton(
            icon: const Icon(Icons.person_outline_rounded),
            onPressed: () => Navigator.pushNamed(context, '/profile'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Salom xabari
            Text(
              'Salom, ${auth.user?.fullName.split(' ').first ?? 'Foydalanuvchi'}! 👋',
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fadeIn().slideX(begin: -0.1),
            const SizedBox(height: 6),
            Text(
              'Faylingizni yuklang va AI tahlil qilsin',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 32),

            // Upload zone
            GestureDetector(
              onTap: _pickFile,
              child: DottedBorder(
                color: _isDragging ? const Color(0xFF6C63FF) : Colors.white24,
                strokeWidth: 2,
                borderType: BorderType.RRect,
                radius: const Radius.circular(20),
                dashPattern: const [8, 4],
                child: AnimatedContainer(
                  duration: 300.ms,
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: _isDragging
                        ? const Color(0xFF6C63FF).withOpacity(0.1)
                        : Colors.white.withOpacity(0.03),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 56,
                        color: _isDragging ? const Color(0xFF6C63FF) : Colors.white38,
                      ).animate(onPlay: (c) => c.repeat(reverse: true))
                          .move(begin: const Offset(0, -4), end: const Offset(0, 4), duration: 1500.ms),
                      const SizedBox(height: 12),
                      Text(
                        'Fayl yuklash uchun bosing',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'JPG · PNG · PDF · DOCX (max 20MB)',
                        style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 16),

            // Kameradan olish tugmasi
            OutlinedButton.icon(
              onPressed: _pickFromCamera,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF6C63FF),
                side: const BorderSide(color: Color(0xFF6C63FF)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              ),
              icon: const Icon(Icons.camera_alt_outlined),
              label: const Text('Kameradan olish'),
            ).animate().fadeIn(delay: 300.ms),

            const SizedBox(height: 28),

            // Sozlamalar
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sozlamalar', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Rasm sifatini oshirish', style: TextStyle(color: Colors.white)),
                      Switch(
                        value: _enhance,
                        onChanged: (v) => setState(() => _enhance = v),
                        activeColor: const Color(0xFF6C63FF),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('Til aniqlash rejimi', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'auto', label: Text('Auto'), icon: Icon(Icons.auto_mode)),
                      ButtonSegment(value: 'latin-only', label: Text('Latin'), icon: Icon(Icons.translate)),
                    ],
                    selected: {_mode},
                    onSelectionChanged: (s) => setState(() => _mode = s.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) =>
                          states.contains(WidgetState.selected)
                              ? const Color(0xFF6C63FF).withOpacity(0.2)
                              : Colors.transparent),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),

            // Loading indikator
            if (analysis.isLoading) ...[
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF6C63FF).withOpacity(0.1),
                  border: Border.all(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF6C63FF), strokeWidth: 2),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('AI tahlil qilmoqda...', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          Text('OCR → Til aniqlash → NLP', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),
            ],
          ],
        ),
      ),
    );
  }
}
