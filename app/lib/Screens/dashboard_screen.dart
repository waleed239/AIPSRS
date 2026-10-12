import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../providers/theme_provider.dart';
import 'video_input_screen.dart';
import 'history_screen.dart';
import 'about_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  String userName = "User";
  String greeting = "Hello";
  String greetingEmoji = "👋";
  String? userId;
  String? avatarUrl;
  bool isUploadingAvatar = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
      fetchUserName();
    }
    _setGreeting();
    _initAnimation();
    ensureUserProfile().then((_) => fetchAvatar());
  }

  Future<void> ensureUserProfile() async {
    if (userId == null) return;
    final existing = await supabase
        .from('profiles')
        .select('id')
        .eq('id', userId!)
        .maybeSingle();
    if (existing == null) {
      await supabase.from('profiles').insert({
        'id': userId!,
        'full_name': userName,
        'avatar_url': null,
      });
    }
  }

  Future<void> fetchUserName() async {
    final authUser = supabase.auth.currentUser;
    if (authUser != null) {
      final displayName = authUser.userMetadata?['display_name'] ?? "User";
      setState(() {
        userName = displayName;
      });
    }
  }

  void _setGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      greeting = "Good Morning";
      greetingEmoji = "☀️";
    } else if (hour < 17) {
      greeting = "Good Afternoon";
      greetingEmoji = "🌤️";
    } else {
      greeting = "Good Evening";
      greetingEmoji = "🌙";
    }
  }

  void _initAnimation() {
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(_animationController);
    _animationController.forward();
  }

  Future<void> fetchAvatar() async {
    if (userId == null) return;
    final response = await supabase
        .from('profiles')
        .select('avatar_url, full_name')
        .eq('id', userId!)
        .maybeSingle();
    if (response != null) {
      setState(() {
        avatarUrl = response['avatar_url'];
        final fetchedName = response['full_name'];
        if (fetchedName != null && fetchedName.isNotEmpty) {
          userName = fetchedName;
        }
      });
    }
  }

  Future<void> pickAndUploadAvatar() async {
    if (userId == null) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() => isUploadingAvatar = true);
    try {
      final file = File(picked.path);
      final path = '$userId/avatar.jpg';

      await supabase.storage.from('avatars').upload(
        path,
        file,
        fileOptions: const FileOptions(upsert: true),
      );

      final publicUrl = supabase.storage.from('avatars').getPublicUrl(path);

      await supabase
          .from('profiles')
          .update({'avatar_url': publicUrl})
          .eq('id', userId!)
          .select();

      setState(() {
        avatarUrl = publicUrl;
        isUploadingAvatar = false;
      });
    } catch (e) {
      print('Error uploading avatar: $e');
      setState(() => isUploadingAvatar = false);
    }
  }

  Future<void> deleteAvatar() async {
    if (userId == null || avatarUrl == null) return;
    setState(() => isUploadingAvatar = true);
    try {
      final path = '$userId/avatar.jpg';
      await supabase.storage.from('avatars').remove([path]);
      await supabase
          .from('profiles')
          .update({'avatar_url': null})
          .eq('id', userId!)
          .select();
      setState(() {
        avatarUrl = null;
        isUploadingAvatar = false;
      });
    } catch (e) {
      print('Error deleting avatar: $e');
      setState(() => isUploadingAvatar = false);
    }
  }

  Future<void> editName() async {
    final controller = TextEditingController(text: userName);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Name'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        await supabase
            .from('profiles')
            .update({'full_name': result})
            .eq('id', userId!)
            .select();
        setState(() => userName = result);
      } catch (e) {
        print('Error updating name: $e');
      }
    }
  }

  void logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // --------------------- BUILD ---------------------
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : Colors.blue.shade100,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: isDark ? Colors.grey[900] : Colors.blue,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () => themeProvider.toggleTheme(),
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isDark
                ? [Colors.grey[900]!, Colors.black]
                : [Colors.blue.shade500, Colors.blue.shade300, Colors.white.withOpacity(0.3)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Column(
              children: [
                _buildHeader(isDark),
                Expanded(child: _buildCards(isDark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: pickAndUploadAvatar,
            onLongPress: () {
              if (avatarUrl != null) {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Avatar Options'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ListTile(
                          leading: const Icon(Icons.visibility),
                          title: const Text('View'),
                          onTap: () {
                            Navigator.pop(context);
                            showDialog(
                              context: context,
                              builder: (_) => Dialog(
                                child: InteractiveViewer(
                                  child: Image.network(
                                    avatarUrl!,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text('Delete'),
                          onTap: () async {
                            Navigator.pop(context);
                            await deleteAvatar();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }
            },
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: isDark ? Colors.grey[800] : Colors.white,
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                    userName[0].toUpperCase(),
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.blue),
                  )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: Colors.blue,
                    child: isUploadingAvatar
                        ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Icon(Icons.edit, size: 14, color: Colors.white),
                  ),
                )
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '$greeting $greetingEmoji, $userName',
                        style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    IconButton(
                      onPressed: editName,
                      icon: Icon(Icons.edit, color: isDark ? Colors.white : Colors.black),
                    )
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your silent speech videos efficiently',
                  style: TextStyle(color: isDark ? Colors.white70 : Colors.black54),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- CARDS ----------------
  Widget _buildCards(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          _card(Icons.video_call, 'New Input', Colors.blueAccent, () {
            if (userId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => VideoInputScreen(userId: userId!)),
              );
            }
          }, isDark),
          _card(Icons.history, 'History', Colors.orangeAccent, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const HistoryScreen()));
          }, isDark),
          _card(Icons.info_outline, 'About', Colors.green, () {
            Navigator.push(
                context, MaterialPageRoute(builder: (_) => const AboutScreen()));
          }, isDark),
          _card(Icons.logout, 'Logout', Colors.redAccent, logout, isDark),
        ],
      ),
    );
  }

  Widget _card(
      IconData icon, String label, Color color, VoidCallback onTap, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black)),
            ),
            Icon(Icons.arrow_forward_ios,
                size: 18, color: isDark ? Colors.white70 : Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
