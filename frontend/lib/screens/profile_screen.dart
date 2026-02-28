import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF3D5AFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  user?.fullName.isNotEmpty == true
                      ? user!.fullName[0].toUpperCase()
                      : 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 20),
            Text(
              user?.fullName ?? '',
              style: const TextStyle(
                  color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 4),
            Text(
              user?.email ?? '',
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
            ).animate().fadeIn(delay: 150.ms),
            const SizedBox(height: 8),
            // Role badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: user?.isAdmin == true
                    ? const Color(0xFFFF8E53).withOpacity(0.15)
                    : const Color(0xFF6C63FF).withOpacity(0.15),
                border: Border.all(
                  color: user?.isAdmin == true
                      ? const Color(0xFFFF8E53).withOpacity(0.4)
                      : const Color(0xFF6C63FF).withOpacity(0.4),
                ),
              ),
              child: Text(
                user?.isAdmin == true ? '👑 Admin' : '👤 Foydalanuvchi',
                style: TextStyle(
                  color: user?.isAdmin == true
                      ? const Color(0xFFFF8E53)
                      : const Color(0xFF6C63FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),

            // Info kartochkasi
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Column(
                children: [
                  _ProfileRow(
                    icon: Icons.person_outline,
                    label: 'To\'liq ism',
                    value: user?.fullName ?? '-',
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _ProfileRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '-',
                  ),
                  const Divider(color: Colors.white12, height: 24),
                  _ProfileRow(
                    icon: Icons.calendar_today_outlined,
                    label: 'Ro\'yxatdan o\'tilgan',
                    value: user != null
                        ? DateFormat('dd.MM.yyyy').format(user.createdAt.toLocal())
                        : '-',
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

            const SizedBox(height: 24),

            // Admin panel
            if (user?.isAdmin == true) ...[
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/admin'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFFF8E53),
                    side: const BorderSide(color: Color(0xFFFF8E53)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  icon: const Icon(Icons.admin_panel_settings_outlined),
                  label: const Text('Admin Paneli'),
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 12),
            ],

            // Chiqish tugmasi
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await auth.logout();
                  if (context.mounted) {
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.withOpacity(0.15),
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red, width: 0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                ),
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Chiqish', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ).animate().fadeIn(delay: user?.isAdmin == true ? 500.ms : 400.ms),
          ],
        ),
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _ProfileRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF6C63FF), size: 20),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Colors.white, fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
