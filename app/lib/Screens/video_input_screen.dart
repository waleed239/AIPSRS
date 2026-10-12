import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_compress/video_compress.dart';
import 'recognition_result_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class VideoInputScreen extends StatefulWidget {
  final String userId;
  const VideoInputScreen({super.key, required this.userId});

  @override
  State<VideoInputScreen> createState() => _VideoInputScreenState();
}

class _VideoInputScreenState extends State<VideoInputScreen> {
  bool _isLoading = false;
  File? _videoFile;
  File? _thumbnailFile;

  final String baseUrl = "....";
  final ImagePicker _picker = ImagePicker();

  static const int maxVideoSeconds = 20;

  Future<void> pickVideo() async {
    _videoFile = null;
    _thumbnailFile = null;
    setState(() {});

    final XFile? pickedFile =
    await _picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile == null) return;

    try {
      final file = File(pickedFile.path);

      // 🔹 Get duration using video_compress (safe)
      final info = await VideoCompress.getMediaInfo(file.path);
      final durationInSeconds = (info.duration! / 1000).round();

      if (durationInSeconds > maxVideoSeconds) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Video must be $maxVideoSeconds seconds or less"),
          ),
        );
        return;
      }

      _videoFile = file;

      // 🔹 Generate thumbnail
      final thumbData = await VideoThumbnail.thumbnailData(
        video: _videoFile!.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 200,
        quality: 75,
      );

      if (thumbData != null) {
        final tempDir = Directory.systemTemp;
        _thumbnailFile =
        await File('${tempDir.path}/thumb.png').writeAsBytes(thumbData);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video selected successfully")),
      );

      setState(() {});
    } catch (e) {
      // 🔥 Simple message for user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Video is too long or not supported"),
        ),
      );
    }
  }

  Future<void> uploadAndRecognize() async {
    if (_videoFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a video first")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse("$baseUrl/predict"),
      );

      request.fields['user_id'] = widget.userId;
      request.files.add(
        await http.MultipartFile.fromPath(
          'video',
          _videoFile!.path,
          contentType: MediaType('video', 'mp4'),
        ),
      );

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final videoPath = _videoFile!.path;

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RecognitionResultScreen(
              userId: widget.userId,
              videoPath: videoPath,
            ),
          ),
        ).then((_) {
          setState(() {
            _videoFile = null;
            _thumbnailFile = null;
          });
        });
      } else {
        final decoded = jsonDecode(responseBody);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(decoded['error'] ?? "Upload failed")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Upload Video"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[850]!, Colors.black]
                : [
              Colors.blue.shade300,
              Colors.blue.shade600,
              Colors.white.withOpacity(0.15)
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
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
                  _thumbnailFile != null
                      ? Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isDark ? Colors.white70 : Colors.black26,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        _thumbnailFile!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  )
                      : Icon(
                    Icons.video_library_outlined,
                    size: 80,
                    color: isDark ? Colors.white70 : Colors.black45,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _videoFile == null
                        ? "No video selected"
                        : "Video ready for recognition",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 25),
                  ElevatedButton.icon(
                    onPressed: pickVideo,
                    icon: const Icon(Icons.upload),
                    label: const Text("Select Video"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blueGrey : Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 15),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : uploadAndRecognize,
                    icon: const Icon(Icons.play_arrow),
                    label: _isLoading
                        ? const Text("Uploading...")
                        : const Text("Upload & Recognize"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDark ? Colors.blueGrey : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
