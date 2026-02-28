import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  bool _showFeedback = false;
  final _feedbackCtrl = TextEditingController();
  String? _selectedLang;
  bool _feedbackSent = false;

  @override
  void dispose() {
    _feedbackCtrl.dispose();
    super.dispose();
  }

  List<String> _parseList(dynamic data) {
    if (data == null) return [];
    if (data is List) return data.cast<String>();
    try {
      return List<String>.from(jsonDecode(data.toString()));
    } catch (_) {
      return data.toString().split(',').map((e) => e.trim()).toList();
    }
  }

  Color _langColor(String? lang) {
    switch (lang) {
      case 'UZ': return const Color(0xFF00C9A7);
      case 'RU': return const Color(0xFF4FC3F7);
      case 'EN': return const Color(0xFF6C63FF);
      case 'QQ': return const Color(0xFFFF8E53);
      default:    return Colors.white38;
    }
  }

  Future<void> _sendFeedback(int historyId) async {
    try {
      await ApiService().submitFeedback(
        historyId: historyId,
        comment: _feedbackCtrl.text.trim().isNotEmpty ? _feedbackCtrl.text.trim() : null,
        correctLang: _selectedLang,
      );
      setState(() { _feedbackSent = true; _showFeedback = false; });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rahmat! Fikringiz qabul qilindi.'), backgroundColor: Color(0xFF00C9A7)),
        );
      }
    } catch (_) {}
  }

  Future<void> _exportPdf(Map<String, dynamic> result, Map<String, dynamic>? sentiment, List<String> entities, List<String> keywords) async {
    final pdf = pw.Document();
    
    // Fallback shrift -> Kirilcha va O'zbekcha harflar uchun
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (pw.Context context) {
          return [
            pw.Header(
               level: 0,
               child: pw.Text('Tahlil Natijasi (BMI OCR+NLP)', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.deepPurple))
            ),
            pw.SizedBox(height: 20),
            
            if (result['summary'] != null) ...[
              pw.Text('Xulosa', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(result['summary']),
              pw.SizedBox(height: 16),
            ],
            
            if (result['translated_summary'] != null) ...[
              pw.Text('Tarjimasi', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(result['translated_summary'], style: const pw.TextStyle(color: PdfColors.blueGrey)),
              pw.SizedBox(height: 16),
            ],

            if (sentiment != null) ...[
               pw.Text('Hissiyot (Sentiment)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 8),
               pw.Text('${sentiment['label']} - Score: ${sentiment['score']}'),
               pw.SizedBox(height: 16),
            ],

            if (entities.isNotEmpty) ...[
               pw.Text('Shaxs va Joy Nomlari (NER)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 8),
               pw.Text(entities.join(', ')),
               pw.SizedBox(height: 16),
            ],

            if (keywords.isNotEmpty) ...[
               pw.Text('Kalit So\'zlar', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 8),
               pw.Text(keywords.join(', ')),
               pw.SizedBox(height: 16),
            ],

            if (result['ocr_text'] != null) ...[
               pw.Text('Asl Matn (OCR)', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
               pw.SizedBox(height: 8),
               pw.Text(result['ocr_text'], style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            ]
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'bmi_ocr_tahlil_${DateTime.now().millisecondsSinceEpoch}.pdf',
    );
  }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();
    final result = analysis.lastResult;

    if (result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Natija')),
        body: const Center(child: Text('Natija topilmadi', style: TextStyle(color: Colors.white54))),
      );
    }

    final keywords = _parseList(result['keywords']);
    final entities = _parseList(result['entities']);
    final lang = result['detected_lang'] as String?;
    final confidence = ((result['lang_confidence'] as num? ?? 0) * 100).round();
    
    // Yengil parse qilingan sentiment objecti
    Map<String, dynamic>? sentiment;
    if (result['sentiment'] != null) {
      if (result['sentiment'] is Map) {
         sentiment = result['sentiment'] as Map<String, dynamic>;
      } else if (result['sentiment'] is String) {
         try {
           sentiment = jsonDecode(result['sentiment']);
         } catch (_) {}
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tahlil Natijasi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined),
            tooltip: 'PDF qilib saqlash',
            onPressed: () => _exportPdf(result, sentiment, entities, keywords),
          ),
          IconButton(
            icon: const Icon(Icons.home_outlined),
            onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Til badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: _langColor(lang).withOpacity(0.15),
                    border: Border.all(color: _langColor(lang).withOpacity(0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.language, color: _langColor(lang), size: 18),
                      const SizedBox(width: 8),
                      Text('$lang · $confidence%',
                          style: TextStyle(color: _langColor(lang), fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                ).animate().fadeIn().scale(),
                const SizedBox(width: 12),
                if (result['category'] != null)
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.05),
                        border: Border.all(color: Colors.white12),
                      ),
                      child: Text(
                        '📂 ${result['category']}',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Xulosa va Tarjima
            if (result['summary'] != null) ...[
              _SectionCard(
                title: '📝 Qisqa Xulosa',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result['summary'],
                      style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.7),
                    ),
                    if (result['translated_summary'] != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Divider(color: Colors.white24),
                      ),
                      const Text('Tarjimasi:', style: TextStyle(color: Colors.white54, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(
                        result['translated_summary'],
                        style: const TextStyle(color: Color(0xFF4FC3F7), fontSize: 14, height: 1.7),
                      ),
                    ]
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],

            // Sentiment (Hissiyot)
            if (sentiment != null) ...[
              _SectionCard(
                title: '🎭 Matn Hissiyoti (Sentiment)',
                child: Row(
                  children: [
                    Text(sentiment['emoji'] ?? '', style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sentiment['label'] ?? 'Noma\'lum', 
                             style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        Text('Score: ${sentiment['score'] ?? 0.0}', 
                             style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],

            // NER (Ismlar va Joylar)
            if (entities.isNotEmpty) ...[
              _SectionCard(
                title: '👤 Shaxs va Joy Nomlari (NER)',
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: entities.map((en) => Chip(
                    label: Text(en, style: const TextStyle(color: Color(0xFF6C63FF))),
                    backgroundColor: const Color(0xFF6C63FF).withOpacity(0.1),
                    side: BorderSide(color: const Color(0xFF6C63FF).withOpacity(0.3)),
                  )).toList(),
                ),
              ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],

            // Kalit so'zlar
            if (keywords.isNotEmpty) ...[
              _SectionCard(
                title: '🔑 Kalit So\'zlar',
                child: Wrap(
                  spacing: 8, runSpacing: 8,
                  children: keywords
                      .map((kw) => Chip(label: Text(kw)))
                      .toList(),
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],

            // OCR Matn
            if (result['ocr_text'] != null) ...[
              _SectionCard(
                title: '📄 Ajratilgan Matn (OCR)',
                action: IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: Colors.white38),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: result['ocr_text']));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Matn nusxalandi')),
                    );
                  },
                ),
                child: SelectableText(
                  result['ocr_text'],
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.6),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
              const SizedBox(height: 16),
            ],

            // Statistika
            Row(
              children: [
                _StatChip(label: 'So\'z', value: '${result['word_count'] ?? 0}'),
                const SizedBox(width: 8),
                _StatChip(label: 'Gap', value: '${result['sentence_count'] ?? 0}'),
                const SizedBox(width: 8),
                _StatChip(label: 'Keyword', value: '${keywords.length}'),
              ],
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),

            // Feedback
            if (!_feedbackSent)
              TextButton.icon(
                onPressed: () => setState(() => _showFeedback = !_showFeedback),
                icon: const Icon(Icons.feedback_outlined, color: Colors.white38),
                label: const Text('Natija noto\'g\'rimi? Xabar bering',
                    style: TextStyle(color: Colors.white38, fontSize: 12)),
              ),
            if (_showFeedback && result['id'] != null)
              _FeedbackForm(
                historyId: result['id'],
                selectedLang: _selectedLang,
                controller: _feedbackCtrl,
                onLangChanged: (v) => setState(() => _selectedLang = v),
                onSend: () => _sendFeedback(result['id']),
              ).animate().fadeIn(),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final Widget? action;
  const _SectionCard({required this.title, required this.child, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title,
                  style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 13)),
              if (action != null) ...[const Spacer(), action!],
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label, value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 11)),
        ],
      ),
    );
  }
}

class _FeedbackForm extends StatelessWidget {
  final int historyId;
  final String? selectedLang;
  final TextEditingController controller;
  final ValueChanged<String?> onLangChanged;
  final VoidCallback onSend;

  const _FeedbackForm({
    required this.historyId, required this.selectedLang,
    required this.controller, required this.onLangChanged, required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFFF6B6B).withOpacity(0.05),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('To\'g\'ri til:', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['UZ', 'RU', 'EN', 'QQ'].map((lang) {
              final selected = selectedLang == lang;
              return ChoiceChip(
                label: Text(lang),
                selected: selected,
                onSelected: (_) => onLangChanged(lang),
                selectedColor: const Color(0xFF6C63FF).withOpacity(0.3),
                labelStyle: TextStyle(color: selected ? const Color(0xFF6C63FF) : Colors.white54),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            style: const TextStyle(color: Colors.white, fontSize: 13),
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Izoh (ixtiyoriy)...',
              hintStyle: TextStyle(color: Colors.white24),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: onSend, child: const Text('Yuborish')),
        ],
      ),
    );
  }
}
