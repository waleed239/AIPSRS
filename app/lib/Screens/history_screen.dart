import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'prediction_result_screen.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  Set<String> _selectedUuids = {};

  final String baseUrl = "...";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final accessToken = session?.accessToken;
      if (accessToken == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/history'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        setState(() {
          _history = data.map((e) {
            final item = Map<String, dynamic>.from(e);
            if (item['prediction'] != null) {
              try {
                final predJson = json.decode(item['prediction']);
                if (predJson is Map<String, dynamic> && predJson['transcript'] != null) {
                  item['prediction'] = predJson['transcript'];
                }
              } catch (_) {}
            }
            return item;
          }).toList();
          _selectedUuids.clear();
        });
      }
    } catch (e) {
      debugPrint("History error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String uuid) async {
    final confirm = await _showConfirmationDialog("Delete video?", "Are you sure you want to delete this video?");
    if (!confirm) return;

    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    await http.delete(
      Uri.parse('$baseUrl/history/$uuid'),
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Video deleted")));
  }

  Future<void> _deleteSelected() async {
    if (_selectedUuids.isEmpty) return;
    final confirm = await _showConfirmationDialog(
        "Delete selected videos?", "Delete ${_selectedUuids.length} selected item(s)?");
    if (!confirm) return;

    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;

    for (final uuid in _selectedUuids) {
      await http.delete(
        Uri.parse('$baseUrl/history/$uuid'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );
    }

    _selectedUuids.clear();
    _loadHistory();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selected videos deleted")));
  }

  Future<bool> _showConfirmationDialog(String title, String content) async {
    return (await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete")),
        ],
      ),
    )) ?? false;
  }

  String _formatTimestamp(String value) {
    final dt = DateTime.tryParse(value);
    if (dt == null) return '';
    return "${dt.day}/${dt.month}/${dt.year}";
  }

  void _toggleSelect(String uuid) {
    setState(() {
      if (_selectedUuids.contains(uuid)) {
        _selectedUuids.remove(uuid);
      } else {
        _selectedUuids.add(uuid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("History"),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_selectedUuids.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_outline, color: isDark ? Colors.white : Colors.black),
              onPressed: _deleteSelected,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[850]!, Colors.black]
                : [Colors.blue.shade400, Colors.blue.shade700, Colors.white.withOpacity(0.2)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: isDark ? Colors.white : Colors.black))
            : _history.isEmpty
            ? Center(
          child: Text(
            "No history available",
            style: GoogleFonts.poppins(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 18,
            ),
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
          itemCount: _history.length,
          itemBuilder: (context, index) {
            final item = _history[index];
            final uuid = item['uuid'] ?? '';
            final selected = _selectedUuids.contains(uuid);

            return GestureDetector(
              onLongPress: () => _toggleSelect(uuid),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => PredictionResultScreen(
                    prediction: item['prediction'] ?? "Processing...",
                    videoName: item['video_name'] ?? "Result",
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: selected
                      ? (isDark ? Colors.blueAccent.withOpacity(0.35) : Colors.blueAccent.withOpacity(0.2))
                      : (isDark ? Colors.grey[800] : Colors.white.withOpacity(0.12)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? Colors.white24 : Colors.black26,
                      width: 0.8),
                ),
                child: ListTile(
                  leading: Icon(Icons.video_library, color: isDark ? Colors.white : Colors.black87),
                  title: Text(
                    item['video_name'] ?? 'Video',
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    item['prediction']?.toString().isNotEmpty == true
                        ? item['prediction']
                        : "Processing...",
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white70 : Colors.black54,
                      fontSize: 13,
                    ),
                  ),
                  trailing: Text(
                    _formatTimestamp(item['created_at'] ?? ''),
                    style: GoogleFonts.poppins(
                      color: isDark ? Colors.white54 : Colors.black45,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
