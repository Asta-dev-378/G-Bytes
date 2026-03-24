import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/user_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleStart() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Please enter your name to start!',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    await context.read<UserProvider>().login(name);

    if (mounted) {
      context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    const background = Color(0xFFF8F7FF);

    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background blobs
          Positioned(
            top: -100,
            right: -50,
            child:
                Container(
                      width: 300,
                      height: 300,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary.withValues(alpha: 0.05),
                      ),
                    )
                    .animate()
                    .scale(duration: 2.seconds, curve: Curves.easeInOut)
                    .fadeIn(),
          ),
          Positioned(
            bottom: -80,
            left: -80,
            child:
                Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF6C63FF).withValues(alpha: 0.04),
                      ),
                    )
                    .animate()
                    .scale(duration: 2.5.seconds, curve: Curves.easeInOut)
                    .fadeIn(),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // App Branding
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: primary.withValues(alpha: 0.3),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 32,
                        ),
                      ).animate().scale().rotate(
                        begin: -0.1,
                        end: 0,
                        duration: 600.ms,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'G-Bytes',
                        style: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF1A1A1A),
                          letterSpacing: -1,
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideX(begin: -0.2),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text(
                    'Welcome to your\nPersonal Growth Zone',
                    style: GoogleFonts.poppins(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A1A),
                      height: 1.2,
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2),

                  const SizedBox(height: 12),

                  Text(
                    'Level up your focus, memory, and habits every single day.',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ).animate().fadeIn(delay: 600.ms),

                  const Spacer(),

                  // Login Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'What should we call you?',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            hintText: 'Enter your name...',
                            hintStyle: GoogleFonts.poppins(
                              color: Colors.grey.shade400,
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(
                              0xFFF0F0FF,
                            ).withValues(alpha: 0.5),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            prefixIcon: const Icon(
                              Icons.person_outline,
                              size: 20,
                            ),
                          ),
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A1A1A),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleStart,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 4,
                              shadowColor: primary.withValues(alpha: 0.4),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    'Get Started',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
