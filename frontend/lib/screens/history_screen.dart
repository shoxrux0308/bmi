import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _searchCtrl = TextEditingController();
  String? _selectedLang;
  bool _isLoading = false;

  static const _langs = ['Barchasi', 'UZ', 'RU', 'EN', 'QQ'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    final provider = context.read<AnalysisProvider>();
    await provider.loadHistory(
      lang: (_selectedLang != null && _selectedLang != 'Barchasi') ? _selectedLang : null,
      search: _searchCtrl.text.trim().isNotEmpty ? _searchCtrl.text.trim() : null,
    );
    if (mounted) setState(() => _isLoading = false);
  }

  Color _langColor(String? lang) {
    switch (lang) {
      case 'UZ': return const Color(0xFF00C9A7);
      case 'RU': return const Color(0xFF4FC3F7);
      case 'EN': return const Color(0xFF6C63FF);
      case 'QQ': return const Color(0xFFFF8E53);
      default: return Colors.white38;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = context.watch<AnalysisProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarix'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(112),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Qidiruv
                TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  onSubmitted: (_) => _load(),
                  decoration: InputDecoration(
                    hintText: 'Qidirish...',
                    prefixIcon: const Icon(Icons.search, color: Colors.white38),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search, color: Color(0xFF6C63FF)),
                      onPressed: _load,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
                const SizedBox(height: 8),
                // Til filtri
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: _langs.map((lang) {
                      final selected = (lang == 'Barchasi' && _selectedLang == null) ||
                          lang == _selectedLang;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(lang),
                          selected: selected,
                          onSelected: (_) {
                            setState(() => _selectedLang = lang == 'Barchasi' ? null : lang);
                            _load();
                          },
                          selectedColor: const Color(0xFF6C63FF).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: selected ? const Color(0xFF6C63FF) : Colors.white54,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : analysis.history.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.history_outlined, color: Colors.white24, size: 64),
                      const SizedBox(height: 16),
                      Text('Tarix bo\'sh', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: analysis.history.length,
                  itemBuilder: (context, i) {
                    final item = analysis.history[i];
                    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt.toLocal());
                    return Dismissible(
                      key: Key('history_${item.id}'),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.red.withOpacity(0.2),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                      onDismissed: (_) => analysis.deleteHistory(item.id),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white.withOpacity(0.04),
                          border: Border.all(color: Colors.white.withOpacity(0.08)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: _langColor(item.detectedLang).withOpacity(0.15),
                              ),
                              child: Center(
                                child: Text(
                                  item.detectedLang ?? '?',
                                  style: TextStyle(
                                    color: _langColor(item.detectedLang),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.filename,
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.summary ?? 'Xulosa yo\'q',
                                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              item.fileType == 'pdf'
                                  ? Icons.picture_as_pdf_outlined
                                  : Icons.image_outlined,
                              color: Colors.white24,
                              size: 18,
                            ),
                          ],
                        ),
                      ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.05),
                    );
                  },
                ),
    );
  }
}
