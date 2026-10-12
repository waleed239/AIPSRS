import 'package:flutter/material.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart'; // Make sure you have ThemeProvider

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final gradientColors = isDark
        ? [Colors.grey[900]!, Colors.black, Colors.grey[850]!]
        : [Colors.blue.shade300, Colors.blue.shade600, Colors.white.withOpacity(0.0)];

    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final containerColor = isDark ? Colors.grey[850]!.withOpacity(0.25) : Colors.white.withOpacity(0.15);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("About"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: textColor,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 16),
            child: GlassContainer(
              blur: 25,
              opacity: 0.25,
              borderRadius: BorderRadius.circular(30),
              shadowStrength: 6,
              shadowColor: Colors.white.withOpacity(0.15),
              child: Container(
                width: size.width * 0.85,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // App Icon / Logo
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: containerColor,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.hearing,
                          size: 40,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "AI Powered Silent Speech Recognition System",
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Version 1.0.0",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "This application helps speech-impaired individuals by recognizing silent speech from videos. Developed as a Full-Stack AI-powered project using Flutter, TensorFlow Lite, and Flask backend.",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    Divider(color: Colors.white24, thickness: 1),
                    const SizedBox(height: 20),
                    Text(
                      "Developers",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Muhammad Waleed Wazir\nEmail: waleed36136@gmail.com",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Mohammad Adil\nEmail: adilkhokhar333@gmail.com",
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: secondaryTextColor,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "© 2025 Silent Speech Recognition Project",
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: secondaryTextColor.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}