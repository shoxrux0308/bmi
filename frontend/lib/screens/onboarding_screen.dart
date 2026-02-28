import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  final _pages = [
    _OnboardingData(
      icon: Icons.upload_file_rounded,
      title: 'Fayl Yuklang',
      subtitle: 'Rasm, PDF yoki skrinshotni yuklang.\nDrag&drop yoki kamera orqali.',
      gradient: [Color(0xFF6C63FF), Color(0xFF3D5AFE)],
    ),
    _OnboardingData(
      icon: Icons.auto_awesome_rounded,
      title: 'AI Tahlil Qiladi',
      subtitle: 'OCR, til aniqlash, qisqa xulosa,\nkalit so\'zlar va kategoriya.',
      gradient: [Color(0xFF00C9A7), Color(0xFF00A8CC)],
    ),
    _OnboardingData(
      icon: Icons.download_rounded,
      title: 'Eksport Qiling',
      subtitle: 'Natijani PDF yoki DOCX formatida\nsaqlab, ulashing.',
      gradient: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                child: const Text('O\'tkazib yuborish',
                    style: TextStyle(color: Colors.white38)),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemCount: _pages.length,
                itemBuilder: (context, i) => _OnboardingPage(data: _pages[i]),
              ),
            ),
            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: 300.ms,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? const Color(0xFF6C63FF)
                        : Colors.white24,
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_currentPage < _pages.length - 1) {
                      _controller.nextPage(
                          duration: 400.ms, curve: Curves.easeInOut);
                    } else {
                      Navigator.pushReplacementNamed(context, '/login');
                    }
                  },
                  child: Text(
                    _currentPage < _pages.length - 1 ? 'Keyingisi' : 'Boshlash',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingData {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  const _OnboardingData(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.gradient});
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  const _OnboardingPage({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: data.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: data.gradient.first.withOpacity(0.4),
                  blurRadius: 50,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Icon(data.icon, size: 80, color: Colors.white),
          )
              .animate()
              .scale(duration: 500.ms, curve: Curves.easeOutBack)
              .then()
              .shake(hz: 1, duration: 500.ms),
          const SizedBox(height: 48),
          Text(
            data.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          Text(
            data.subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 16,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }
}
