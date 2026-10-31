import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CineVoraApp());
}

class CineVoraApp extends StatelessWidget {
  const CineVoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVora Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        primaryColor: const Color(0xFFE50914),
        fontFamily: 'Roboto',
      ),
      home: const SplashScreen(),
    );
  }
}

// ---------------- API SERVICES ----------------
class ApiService {
  static const String baseUrl = 'http://cinevorafilms.in/api/index.php';

  static Future> getFeed({int userId = 0}) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl?action=get_feed&user_id=$userId'));
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
    } catch (_) {}
    return {'status': 'error'};
  }

  static Future> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error', 'message': 'Network error'};
  }

  static Future> signup(String name, String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl?action=signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': password}),
      );
      return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error', 'message': 'Network error'};
  }

  static Future<void> trackWatch(int movieId, int userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl?action=track_watch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'movie_id': movieId, 'user_id': userId}),
      );
    } catch (_) {}
  }

  static Future<void> trackDownload(int movieId, int userId) async {
    try {
      await http.post(
        Uri.parse('$baseUrl?action=track_download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'movie_id': movieId, 'user_id': userId}),
      );
    } catch (_) {}
  }

  static Future> verifyPayment(int userId, int planId, double amount, String txId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl?action=verify_payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'plan_id': planId,
          'amount': amount,
          'payment_id': txId,
        }),
      );
      return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error'};
  }
}

// ---------------- SPLASH SCREEN ----------------
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _route();
  }

  Future<void> _route() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid') ?? 0;
    if (!mounted) return;
    if (uid > 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'CINEVORA',
              style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Color(0xFFE50914), letterSpacing: 3),
            ),
            SizedBox(height: 8),
            Text('FILMS & ENTERTAINMENT', style: TextStyle(fontSize: 10, letterSpacing: 2, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

// ---------------- AUTH SCREEN ----------------
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final nameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  bool loading = false;

  Future<void> _handleAuth() async {
    final email = emailCtrl.text.trim();
    final pass = passCtrl.text.trim();
    if (email.isEmpty || pass.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Details complete bharein!')));
      return;
    }
    setState(() => loading = true);

    Map<String, dynamic> res;
    if (isLogin) {
      res = await ApiService.login(email, pass);
    } else {
      final name = nameCtrl.text.trim();
      res = await ApiService.signup(name.isEmpty ? 'Viewer' : name, email, pass);
    }

    setState(() => loading = false);

    if (res['status'] == 'success') {
      final user = res['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', user['id']);
      await prefs.setString('name', user['name'] ?? '');
      await prefs.setString('email', user['email'] ?? '');
      await prefs.setInt('is_vip', user['is_premium'] ?? 0);

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainNavigationScreen()));
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Error occurred')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('CINEVORA', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Color(0xFFE50914))),
                const SizedBox(height: 30),
                if (!isLogin) ...[
                  TextField(
                    controller: nameCtrl,
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      filled: true,
                      fillColor: const Color(0xFF141A26),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    filled: true,
                    fillColor: const Color(0xFF141A26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: passCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    filled: true,
                    fillColor: const Color(0xFF141A26),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE50914),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: loading ? null : _handleAuth,
                    child: loading ? const CircularProgressIndicator(color: Colors.white) : Text(isLogin ? 'Sign In' : 'Create Account'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() => isLogin = !isLogin),
                  child: Text(isLogin ? 'New user? Register now' : 'Existing user? Login here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- MAIN BOTTOM NAV ----------------
class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const HomeScreen(),
    const SeriesScreen(),
    const TeasersScreen(),
    const VipScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: const Color(0xFF0F131C),
        selectedItemColor: const Color(0xFFE50914),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_collection), label: 'Series'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Teasers'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'VIP Pass'),
        ],
      ),
    );
  }
}

// ---------------- HOME SCREEN ----------------
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> data = {};
  bool loading = true;
  int userId = 0;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('uid') ?? 0;
    final res = await ApiService.getFeed(userId: userId);
    if (mounted) {
      setState(() {
        data = res;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFFE50914))));
    }

    final featured = data['featured'];
    final trending = (data['trending'] as List?) ?? [];
    final bhojpuri = (data['bhojpuri'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F131C),
        elevation: 0,
        title: const Text('CINEVORA', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFE50914), letterSpacing: 2)),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: () {}),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadFeed,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Featured Banner
              if (featured != null)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(movie: featured, userId: userId))),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      CachedNetworkImage(
                        imageUrl: featured['poster'] ?? '',
                        height: 380,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(height: 380, color: Colors.grey[900]),
                      ),
                      Container(
                        height: 380,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, const Color(0xFF0B0E14).withOpacity(0.95)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(featured['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(movie: featured, userId: userId))),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Watch Now'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

              // Bhojpuri Hits Section
              if (bhojpuri.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('🔥 Bhojpuri Blockbusters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: bhojpuri.length,
                    itemBuilder: (context, i) => _buildCard(bhojpuri[i]),
                  ),
                ),
              ],

              // Trending Movies
              if (trending.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('🎬 Trending Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 190,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: trending.length,
                    itemBuilder: (context, i) => _buildCard(trending[i]),
                  ),
                ),
              ],
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(movie: item, userId: userId))),
      child: Container(
        width: 125,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedNetworkImage(
                imageUrl: item['poster'] ?? '',
                height: 155,
                width: 125,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(height: 155, color: Colors.grey[900]),
              ),
            ),
            const SizedBox(height: 4),
            Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

// ---------------- VIDEO PLAYER SCREEN ----------------
class PlayerScreen extends StatefulWidget {
  final Map<String, dynamic> movie;
  final int userId;
  const PlayerScreen({super.key, required this.movie, required this.userId});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isInit = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
    ApiService.trackWatch(int.tryParse(widget.movie['id'].toString()) ?? 0, widget.userId);
  }

  Future<void> _initVideo() async {
    final url = widget.movie['video_url'] ?? '';
    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: const Color(0xFFE50914),
        handleColor: const Color(0xFFE50914),
      ),
    );
    setState(() => isInit = true);
  }

  @override
  void dispose() {
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 220,
            color: Colors.black,
            child: isInit && _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const Center(child: CircularProgressIndicator(color: Color(0xFFE50914))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.movie['title'] ?? '', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text(
                  '${widget.movie['year'] ?? '2026'} • ${widget.movie['duration'] ?? '2h'} • ${widget.movie['category'] ?? 'Cinema'}',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF1B2230)),
                  onPressed: () {
                    ApiService.trackDownload(int.tryParse(widget.movie['id'].toString()) ?? 0, widget.userId);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading started...')));
                  },
                  icon: const Icon(Icons.download),
                  label: const Text('Download Movie'),
                ),
                const SizedBox(height: 14),
                Text(widget.movie['description'] ?? 'No synopsis available.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

// ---------------- SERIES SCREEN ----------------
class SeriesScreen extends StatefulWidget {
  const SeriesScreen({super.key});

  @override
  State<SeriesScreen> createState() => _SeriesScreenState();
}

class _SeriesScreenState extends State<SeriesScreen> {
  List series = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.getFeed();
    if (mounted) {
      setState(() {
        series = res['series'] ?? [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Web Series & Originals'), backgroundColor: const Color(0xFF0F131C)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: series.length,
              itemBuilder: (context, i) {
                final s = series[i];
                return Card(
                  color: const Color(0xFF121620),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: s['thumbnail'] ?? '', width: 50, height: 70, fit: BoxFit.cover),
                    ),
                    title: Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s['seasons_count'] ?? 1} Seasons', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- TEASERS & ANNOUNCEMENTS ----------------
class TeasersScreen extends StatefulWidget {
  const TeasersScreen({super.key});

  @override
  State<TeasersScreen> createState() => _TeasersScreenState();
}

class _TeasersScreenState extends State<TeasersScreen> {
  List teast = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.getFeed();
    if (mounted) {
      setState(() {
        teast = res['announcements'] ?? [];
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Coming Soon & Teasers'), backgroundColor: const Color(0xFF0F131C)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teast.length,
              itemBuilder: (context, i) {
                final t = teast[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: const Color(0xFF121620), borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                        child: CachedNetworkImage(imageUrl: t['thumbnail'] ?? '', height: 180, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('${t['tag']} • ${t['release_date']}', style: const TextStyle(color: Color(0xFFE50914), fontSize: 12, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}

// ---------------- VIP SUBSCRIPTION (AUTO-UPI PAYMENT) ----------------
class VipScreen extends StatefulWidget {
  const VipScreen({super.key});

  @override
  State<VipScreen> createState() => _VipScreenState();
}

class _VipScreenState extends State<VipScreen> {
  List plans = [];
  String upiId = 'cinevora@upi';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.getFeed();
    if (mounted) {
      setState(() {
        plans = res['subscription_plans'] ?? [];
        upiId = res['payment_gateways']?['upi_id'] ?? 'cinevora@upi';
        loading = false;
      });
    }
  }

  Future<void> _triggerUpiAndActivate(Map<String, dynamic> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid') ?? 0;
    final price = double.tryParse(plan['price'].toString()) ?? 199.0;
    final planId = int.tryParse(plan['id'].toString()) ?? 1;

    // Direct UPI Intent URL
    final upiUrl = 'upi://pay?pa=$upiId&pn=CineVoraFilms&am=$price&cu=INR&tn=VIP_Pass';
    if (await canLaunchUrl(Uri.parse(upiUrl))) {
      await launchUrl(Uri.parse(upiUrl));
    }

    // Auto verify & Instant Background Activation
    final txId = 'UPI_TXN_${DateTime.now().millisecondsSinceEpoch}';
    final actRes = await ApiService.verifyPayment(uid, planId, price, txId);

    if (actRes['status'] == 'success') {
      await prefs.setInt('is_vip', 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 VIP Subscription Automatically Activated!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CineVora VIP Pass'), backgroundColor: const Color(0xFF0F131C)),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE50914)))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final p = plans[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: const Color(0xFF121620),
                    border: Border.all(color: Colors.amber.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Text(p['plan_name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber)),
                          Text('₹${p['price']}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${p['duration_days']} Days Validity • ${p['quality']} • ${p['device_limit']} Devices', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE50914)),
                          onPressed: () => _triggerUpiAndActivate(p),
                          child: const Text('Subscribe & Pay via UPI', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      )
                    ],
                  ),
                );
              },
            ),
    );
  }
}
