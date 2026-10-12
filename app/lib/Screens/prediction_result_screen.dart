import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class PredictionResultScreen extends StatelessWidget {
  final String prediction;
  final String videoName;

  const PredictionResultScreen({
    super.key,
    required this.prediction,
    required this.videoName,
  });

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final gradientColors = isDark
        ? [Colors.grey[900]!, Colors.black, Colors.grey[850]!]
        : [Colors.blue.shade400, Colors.blue.shade700, Colors.white.withOpacity(0.2)];

    final titleColor = isDark ? Colors.white : Colors.black87;
    final contentColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      height: height * 0.75,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Close button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  videoName,
                  style: GoogleFonts.poppins(
                    color: titleColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: titleColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                prediction.isNotEmpty ? prediction : "Processing...",
                style: GoogleFonts.poppins(
                  color: contentColor,
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
