import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class RecognitionResultScreen extends StatefulWidget {
  final String userId;
  final String? videoPath;

  const RecognitionResultScreen({
    super.key,
    required this.userId,
    this.videoPath,
  });

  @override
  State<RecognitionResultScreen> createState() =>
      _RecognitionResultScreenState();
}

class _RecognitionResultScreenState extends State<RecognitionResultScreen> {
  String displayText = 'Processing video...';
  double confidence = 0.0;
  bool isProcessing = true;
  Timer? _timer;

  // Text-to-Speech
  final FlutterTts flutterTts = FlutterTts();
  bool isSpeaking = false;

  @override
  void initState() {
    super.initState();
    _startPolling();

    flutterTts.setLanguage("en-US");
    flutterTts.setPitch(1.0);
    flutterTts.setSpeechRate(0.5);

    flutterTts.setCompletionHandler(() {
      setState(() => isSpeaking = false);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    flutterTts.stop();
    super.dispose();
  }

  void _copyToClipboard(BuildContext context, String text) {
    if (text.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: text));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text copied!')),
      );
    }
  }

  Future<void> _speakText() async {
    if (!isSpeaking && displayText.isNotEmpty) {
      setState(() => isSpeaking = true);
      await flutterTts.speak(displayText);
    }
  }

  Future<void> _stopSpeaking() async {
    await flutterTts.stop();
    setState(() => isSpeaking = false);
  }

  Future<void> fetchLatestPrediction() async {
    try {
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('predictions')
          .select()
          .eq('user_id', widget.userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final status = response['status'] ?? 'processing';
        final predictionRaw = response['prediction'] ?? '';

        String transcript = predictionRaw;
        try {
          final Map<String, dynamic> parsed = jsonDecode(predictionRaw);
          if (parsed.containsKey('transcript')) {
            transcript = parsed['transcript'] ?? predictionRaw;
          }
        } catch (_) {
          transcript = predictionRaw;
        }

        setState(() {
          displayText = transcript;
          confidence = (response['confidence'] ?? 0.0).toDouble();
          isProcessing = status != 'completed';
        });

        if (status == 'completed') {
          _timer?.cancel();
        }
      }
    } catch (e) {
      debugPrint("Prediction fetch error: $e");
    }
  }

  void _startPolling() {
    fetchLatestPrediction();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      fetchLatestPrediction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final gradientColors = isDark
        ? [Colors.grey[900]!, Colors.black, Colors.grey[850]!]
        : [Colors.blue.shade300, Colors.blue.shade600, Colors.white.withOpacity(0.15)];

    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white70 : Colors.black54;
    final containerColor = isDark ? Colors.grey[850]!.withOpacity(0.25) : Colors.white.withOpacity(0.15);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Recognition Result"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
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
            padding: const EdgeInsets.symmetric(vertical: 40),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Video preview
                    if (widget.videoPath != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          color: containerColor,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.videocam_outlined,
                            size: 60,
                            color: secondaryTextColor,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Recognition Result Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: containerColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Recognized Speech",
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 15),
                          if (isProcessing)
                            Row(
                              children: [
                                CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: textColor,
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  "Processing video...",
                                  style: TextStyle(color: secondaryTextColor),
                                ),
                              ],
                            )
                          else
                            Text(
                              displayText,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                color: textColor,
                              ),
                              textAlign: TextAlign.left,
                            ),
                          if (!isProcessing && confidence > 0)
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                "Confidence: ${(confidence * 100).toStringAsFixed(1)}%",
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Buttons: Try Again + Copy
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => Navigator.pop(context),
                          icon: Icon(Icons.replay, color: textColor),
                          label: const Text("Try Again"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent.shade100,
                            foregroundColor: textColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: isProcessing ? null : () => _copyToClipboard(context, displayText),
                          icon: Icon(Icons.copy, color: textColor),
                          label: const Text("Copy"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.greenAccent.shade400,
                            foregroundColor: textColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Speak / Stop
                    ElevatedButton.icon(
                      onPressed: (isProcessing || displayText.isEmpty)
                          ? null
                          : (isSpeaking ? _stopSpeaking : _speakText),
                      icon: Icon(isSpeaking ? Icons.stop : Icons.volume_up, color: textColor),
                      label: Text(isSpeaking ? "Stop" : "Speak"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent.shade400,
                        foregroundColor: textColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      ),
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
