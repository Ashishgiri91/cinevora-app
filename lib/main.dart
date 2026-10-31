import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';

const Color kRed = Color(0xFFE50914);
const Color kDarkBg = Color(0xFF090A0F);
const Color kCardBg = Color(0xFF141721);
const String kBaseApi = 'http://cinevorafilms.in/api/index.php';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const CineVoraMasterApp());
}

class CineVoraMasterApp extends StatelessWidget {
  const CineVoraMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVora Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kDarkBg,
        primaryColor: kRed,
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0F121B), elevation: 0),
        colorScheme: const ColorScheme.dark(primary: kRed, secondary: Colors.amber),
      ),
      home: const SplashScreen(),
    );
  }
}

// ================= API SERVICE =================
class ApiService {
  static Future> fetchFeed(int userId) async {
    try {
      final res = await http.get(Uri.parse('$kBaseApi?action=get_feed&user_id=$userId')).timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error'};
  }

  static Future> login(String email, String pass) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseApi?action=login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass}),
      );
      return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error', 'message': 'Network connect nahi hua!'};
  }

  static Future> signup(String name, String email, String pass) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseApi?action=signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'name': name, 'email': email, 'password': pass}),
      );
      return jsonDecode(res.body);
    } catch (_) {}
    return {'status': 'error', 'message': 'Registration fail hua!'};
  }

  static Future<void> trackWatch(int movieId, int userId) async {
    try {
      await http.post(
        Uri.parse('$kBaseApi?action=track_watch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'movie_id': movieId, 'user_id': userId}),
      );
    } catch (_) {}
  }

  static Future<void> trackDownload(int movieId, int userId) async {
    try {
      await http.post(
        Uri.parse('$kBaseApi?action=track_download'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'movie_id': movieId, 'user_id': userId}),
      );
    } catch (_) {}
  }

  static Future> verifyPayment(int userId, int planId, double amount, String txId) async {
    try {
      final res = await http.post(
        Uri.parse('$kBaseApi?action=verify_payment'),
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

// ================= SPLASH SCREEN =================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    await Future.delayed(const Duration(seconds: 2));
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid') ?? 0;
    if (!mounted) return;
    if (uid > 0) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CINEVORA', style: TextStyle(fontSize: 42, fontWeight: FontWeight.w900, color: kRed, letterSpacing: 4)),
            SizedBox(height: 8),
            Text('ORIGINAL FILMS & WEB SERIES', style: TextStyle(fontSize: 10, letterSpacing: 3, color: Colors.white54)),
          ],
        ),
      ),
    );
  }
}

// ================= AUTH SCREENS =================
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await ApiService.login(_email.text.trim(), _pass.text.trim());
    setState(() => _loading = false);

    if (res['status'] == 'success') {
      final u = res['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', u['id']);
      await prefs.setString('name', u['name'] ?? '');
      await prefs.setString('email', u['email'] ?? '');
      await prefs.setInt('is_vip', u['is_premium'] ?? 0);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (r) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Login failed!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('CINEVORA', textAlign: TextAlign.center, style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, letterSpacing: 3, color: kRed)),
                  const SizedBox(height: 6),
                  const Text('Welcome back! Enter credentials', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, fontSize: 13)),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Sahi email daalo' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide)),
                      filled: true,
                      fillColor: kCardBg,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Kam se kam 6 akshar daalo' : null,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kRed,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login to Account', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Naya user?'),
                      TextButton(
                        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Register karo', style: TextStyle(color: kRed, fontWeight: FontWeight.bold)),
                      ),
                    ],
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

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;
  bool _loading = false;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _loading = true);

    final res = await ApiService.signup(_name.text.trim(), _email.text.trim(), _pass.text.trim());
    setState(() => _loading = false);

    if (res['status'] == 'success') {
      final u = res['user'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('uid', u['id']);
      await prefs.setString('name', u['name'] ?? '');
      await prefs.setString('email', u['email'] ?? '');
      await prefs.setInt('is_vip', u['is_premium'] ?? 0);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (r) => false);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Signup error!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Naya Account Banao', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                const Text('CineVora OTT me judne ke liye form bharein', style: TextStyle(color: Colors.white54)),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline),
                    filled: true,
                    fillColor: kCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.trim().length < 2) ? 'Naam daalo' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: const Icon(Icons.email_outlined),
                    filled: true,
                    fillColor: kCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || !v.contains('@')) ? 'Sahi email daalo' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _pass,
                  obscureText: _hide,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(icon: Icon(_hide ? Icons.visibility_off : Icons.visibility), onPressed: () => setState(() => _hide = !_hide)),
                    filled: true,
                    fillColor: kCardBg,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (v) => (v == null || v.length < 6) ? 'Kam se kam 6 akshar daalo' : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kRed,
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _loading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Register Account', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================= MAIN SHELL =================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _idx = 0;
  final _tabs = const [
    HomeScreen(),
    SeriesCatalogScreen(),
    TeasersScreen(),
    VipPlansScreen(),
    AccountProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_idx],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        backgroundColor: const Color(0xFF0F121B),
        selectedItemColor: kRed,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.video_collection), label: 'Series'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active), label: 'Teasers'),
          BottomNavigationBarItem(icon: Icon(Icons.workspace_premium), label: 'VIP Pass'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

// ================= HOME SCREEN =================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Map<String, dynamic> feed = {};
  bool loading = true;
  int uid = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    uid = prefs.getInt('uid') ?? 0;
    final res = await ApiService.fetchFeed(uid);
    if (mounted) {
      setState(() {
        feed = res;
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: kRed)));
    }

    final featured = feed['featured'];
    final trending = (feed['trending'] as List?) ?? [];
    final bhojpuri = (feed['bhojpuri'] as List?) ?? [];
    final series = (feed['series'] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('CINEVORA', style: TextStyle(fontWeight: FontWeight.w900, color: kRed, letterSpacing: 2.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SearchCatalogScreen(movies: trending, uid: uid))),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _initData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Hero Featured Banner
              if (featured != null)
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: featured, uid: uid))),
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      CachedNetworkImage(
                        imageUrl: featured['poster'] ?? '',
                        height: 400,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(height: 400, color: kCardBg),
                      ),
                      Container(
                        height: 400,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, kDarkBg.withOpacity(0.95)],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(featured['title'] ?? '', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            const SizedBox(height: 6),
                            Text('${featured['year'] ?? '2026'} • ${featured['category'] ?? 'Cinema'}', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(backgroundColor: kRed),
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: featured, uid: uid))),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Play Movie'),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),

              // 2. Bhojpuri Hits Section
              if (bhojpuri.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('🔥 Bhojpuri Blockbusters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: bhojpuri.length,
                    itemBuilder: (context, i) => _buildCard(bhojpuri[i]),
                  ),
                ),
              ],

              // 3. Trending Movies Section
              if (trending.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('🎬 Trending Movies', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: trending.length,
                    itemBuilder: (context, i) => _buildCard(trending[i]),
                  ),
                ),
              ],

              // 4. Web Series Row
              if (series.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 20, 16, 10),
                  child: Text('🥞 Web Series & Originals', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                SizedBox(
                  height: 195,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: series.length,
                    itemBuilder: (context, i) => _buildSeriesCard(series[i]),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: item, uid: uid))),
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
                height: 160,
                width: 125,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(height: 160, color: kCardBg),
              ),
            ),
            const SizedBox(height: 5),
            Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildSeriesCard(Map<String, dynamic> item) {
    return Container(
      width: 125,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: item['thumbnail'] ?? '',
              height: 160,
              width: 125,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(height: 160, color: kCardBg),
            ),
          ),
          const SizedBox(height: 5),
          Text(item['title'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ================= MOVIE DETAIL & STREAMING =================
class MovieDetailScreen extends StatelessWidget {
  final Map<String, dynamic> movie;
  final int uid;
  const MovieDetailScreen({super.key, required this.movie, required this.uid});

  @override
  Widget build(BuildContext context) {
    final vUrl = movie['video_url'] ?? '';
    final mid = int.tryParse(movie['id'].toString()) ?? 0;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CachedNetworkImage(
              imageUrl: movie['poster'] ?? '',
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(height: 250, color: Colors.grey[900]),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(movie['title'] ?? '', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text('${movie['year'] ?? '2026'} • ${movie['duration'] ?? '2h'} • ${movie['category'] ?? 'Cinema'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: kRed),
                        onPressed: () async {
                          ApiService.trackWatch(mid, uid);
                          final uri = Uri.parse(vUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(uri, mode: LaunchMode.externalApplication);
                          }
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Stream Online'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          ApiService.trackDownload(mid, uid);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading started...')));
                        },
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(movie['description'] ?? 'No storyline details.', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}

// ================= VIP PLANS & AUTO-UPI PAYMENTS =================
class VipPlansScreen extends StatefulWidget {
  const VipPlansScreen({super.key});

  @override
  State<VipPlansScreen> createState() => _VipPlansScreenState();
}

class _VipPlansScreenState extends State<VipPlansScreen> {
  List plans = [];
  String upiId = 'cinevora@upi';
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPlans();
  }

  Future<void> _loadPlans() async {
    final res = await ApiService.fetchFeed(0);
    if (mounted) {
      setState(() {
        plans = res['subscription_plans'] ?? [];
        upiId = res['payment_gateways']?['upi_id'] ?? 'cinevora@upi';
        loading = false;
      });
    }
  }

  Future<void> _payWithUpi(Map<String, dynamic> plan) async {
    final prefs = await SharedPreferences.getInstance();
    final uid = prefs.getInt('uid') ?? 0;
    final price = double.tryParse(plan['price'].toString()) ?? 199.0;
    final planId = int.tryParse(plan['id'].toString()) ?? 1;

    // Direct Universal UPI Intent (GPay, PhonePe, Paytm selector)
    final upiUri = Uri.parse('upi://pay?pa=$upiId&pn=CineVoraFilms&am=$price&cu=INR&tn=VIP_Plan_$planId');

    try {
      if (await canLaunchUrl(upiUri)) {
        await launchUrl(upiUri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {}

    // Instant Backend Auto-Verification in MySQL Database
    final txId = 'UPI_INTENT_${DateTime.now().millisecondsSinceEpoch}';
    final actRes = await ApiService.verifyPayment(uid, planId, price, txId);

    if (actRes['status'] == 'success') {
      await prefs.setInt('is_vip', 1);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('🎉 Payment Successful! VIP Pass Activated.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('CineVora VIP Membership')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: plans.length,
              itemBuilder: (context, i) {
                final p = plans[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: kCardBg,
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
                      Text('${p['duration_days']} Days Validity • ${p['quality']} • ${p['device_limit']} Screens', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: kRed),
                          onPressed: () => _payWithUpi(p),
                          child: const Text('Pay via UPI (GPay / PhonePe)', style: TextStyle(fontWeight: FontWeight.bold)),
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

// ================= SERIES CATALOG SCREEN =================
class SeriesCatalogScreen extends StatefulWidget {
  const SeriesCatalogScreen({super.key});

  @override
  State<SeriesCatalogScreen> createState() => _SeriesCatalogScreenState();
}

class _SeriesCatalogScreenState extends State<SeriesCatalogScreen> {
  List series = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await ApiService.fetchFeed(0);
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
      appBar: AppBar(title: const Text('Web Series & Originals')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: series.length,
              itemBuilder: (context, i) {
                final s = series[i];
                return Card(
                  color: kCardBg,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(imageUrl: s['thumbnail'] ?? '', width: 50, height: 70, fit: BoxFit.cover),
                    ),
                    title: Text(s['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${s['seasons_count'] ?? 1} Seasons Available', style: const TextStyle(color: Colors.amber, fontSize: 12)),
                  ),
                );
              },
            ),
    );
  }
}

// ================= TEASERS & ANNOUNCEMENTS SCREEN =================
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
    final res = await ApiService.fetchFeed(0);
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
      appBar: AppBar(title: const Text('Coming Soon & Teasers')),
      body: loading
          ? const Center(child: CircularProgressIndicator(color: kRed))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: teast.length,
              itemBuilder: (context, i) {
                final t = teast[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: kCardBg, borderRadius: BorderRadius.circular(14)),
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
                            Text('${t['tag']} • ${t['release_date']}', style: const TextStyle(color: kRed, fontSize: 12, fontWeight: FontWeight.bold)),
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

// ================= SEARCH SCREEN =================
class SearchCatalogScreen extends StatefulWidget {
  final List movies;
  final int uid;
  const SearchCatalogScreen({super.key, required this.movies, required this.uid});

  @override
  State<SearchCatalogScreen> createState() => _SearchCatalogScreenState();
}

class _SearchCatalogScreenState extends State<SearchCatalogScreen> {
  List filtered = [];
  final searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    filtered = widget.movies;
  }

  void _onSearch(String q) {
    setState(() {
      filtered = widget.movies.where((m) => m['title'].toString().toLowerCase().contains(q.toLowerCase())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: searchCtrl,
          onChanged: _onSearch,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Search movies, Bhojpuri...', border: InputBorder.none),
        ),
      ),
      body: ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final m = filtered[i];
          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(imageUrl: m['poster'] ?? '', width: 45, height: 60, fit: BoxFit.cover),
            ),
            title: Text(m['title'] ?? ''),
            subtitle: Text(m['category'] ?? 'General'),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MovieDetailScreen(movie: m, uid: widget.uid))),
          );
        },
      ),
    );
  }
}

// ================= ACCOUNT PROFILE SCREEN =================
class AccountProfileScreen extends StatefulWidget {
  const AccountProfileScreen({super.key});

  @override
  State<AccountProfileScreen> createState() => _AccountProfileScreenState();
}

class _AccountProfileScreenState extends State<AccountProfileScreen> {
  String name = 'Viewer';
  String email = '';
  int isVip = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      name = prefs.getString('name') ?? 'Viewer';
      email = prefs.getString('email') ?? '';
      isVip = prefs.getInt('is_vip') ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(radius: 40, backgroundColor: kCardBg, child: Icon(Icons.person, size: 50, color: kRed)),
            const SizedBox(height: 12),
            Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(email, style: const TextStyle(color: Colors.white54, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: isVip == 1 ? Colors.amber.withOpacity(0.2) : Colors.grey.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
              child: Text(isVip == 1 ? '⭐ VIP ACTIVE' : 'FREE USER', style: TextStyle(color: isVip == 1 ? Colors.amber : Colors.grey, fontWeight: FontWeight.bold, fontSize: 11)),
            ),
            const Spacer(),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: kRed, minimumSize: const Size.fromHeight(48)),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                if (!context.mounted) return;
                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
              },
              child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
