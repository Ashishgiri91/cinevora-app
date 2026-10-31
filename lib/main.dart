import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// APNE DOMAIN KA REAL URL
const String kApiBaseUrl = 'https://cinevorafilms.in/api_auth.php';

const kRed = Color(0xFFE50914);
const kBg = Color(0xFF0B0B0F);
const kCardBg = Color(0xFF16161F);

class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isPremium;

  UserModel({required this.id, required this.name, required this.email, required this.isPremium});

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
    );
  }
}

class AppState {
  static UserModel? currentUser;
  static Set<String> myList = {};
  static List<String> watchHistory = [];
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CineVoraApp());
}

class CineVoraApp extends StatelessWidget {
  const CineVoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVora Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: kBg,
        colorScheme: const ColorScheme.dark(primary: kRed),
      ),
      home: const SplashScreen(),
    );
  }
}

// 1. SPLASH SCREEN (Session Auto-Check)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkSavedSession();
  }

  Future<void> _checkSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUserData = prefs.getString('user_session');

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (savedUserData != null && savedUserData.isNotEmpty) {
      final data = jsonDecode(savedUserData);
      AppState.currentUser = UserModel.fromJson(data);
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    } else {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const AuthScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('CINEVORA',
                style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    color: kRed)),
            SizedBox(height: 10),
            Text('FILMS & OTT PLATFORM',
                style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 2,
                    color: Colors.white54,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

// 2. AUTH SCREEN (100% Real PHP API Backend Auth)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  bool isLoading = false;
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final nameController = TextEditingController();

  Future<void> submitAuth() async {
    final email = emailController.text.trim();
    final pass = passController.text.trim();
    final name = nameController.text.trim();

    if (email.isEmpty || pass.isEmpty || (!isLogin && name.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sabhi fields bharna zaroori hai!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(kApiBaseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action': isLogin ? 'login' : 'signup',
          'name': name,
          'email': email,
          'password': pass,
        }),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        final user = UserModel.fromJson(result['user']);
        AppState.currentUser = user;

        // Save session locally so user stays logged in forever
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_session', jsonEncode({
          'id': user.id,
          'name': user.name,
          'email': user.email,
          'is_premium': user.isPremium ? 1 : 0
        }));

        if (!mounted) return;
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainShell()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Authentication failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Server se connect nahi ho paya: $e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              const Center(
                child: Text('CINEVORA',
                    style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w900,
                        color: kRed,
                        letterSpacing: 3)),
              ),
              const SizedBox(height: 40),
              Text(
                isLogin ? 'Welcome Back!' : 'Create Account',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                isLogin
                    ? 'Apne real account se login karein'
                    : 'Naya account banayein aur CineVora access karein',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 30),
              if (!isLogin) ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: 'Aapka Pura Naam',
                    filled: true,
                    fillColor: kCardBg,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined),
                  hintText: 'Email Address',
                  filled: true,
                  fillColor: kCardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passController,
                obscureText: true,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline),
                  hintText: 'Password',
                  filled: true,
                  fillColor: kCardBg,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: isLoading ? null : submitAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(
                        isLogin ? 'Log In' : 'Sign Up',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLogin ? "Account nahi hai? " : "Pehle se account hai? "),
                  GestureDetector(
                    onTap: () => setState(() => isLogin = !isLogin),
                    child: Text(
                      isLogin ? 'Sign Up' : 'Log In',
                      style: const TextStyle(
                          color: kRed, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. MAIN APP SHELL
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    AppState.currentUser = null;
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeTab(),
      const SearchTab(),
      const CategoriesTab(),
      AccountTab(onLogout: logout),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CINEVORA',
            style: TextStyle(color: kRed, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        backgroundColor: const Color(0xFF111116),
        indicatorColor: kRed.withOpacity(0.2),
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: kRed),
              label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.search),
              selectedIcon: Icon(Icons.search, color: kRed),
              label: 'Search'),
          NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view, color: kRed),
              label: 'Categories'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: kRed),
              label: 'Account'),
        ],
      ),
    );
  }
}

// 4. HOME & MOVIES (Live Structure)
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('Trending Now',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

class SearchTab extends StatelessWidget {
  const SearchTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Search Live'));
  }
}

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Categories Live'));
  }
}

// 5. ACCOUNT TAB (Real Data Only)
class AccountTab extends StatelessWidget {
  final VoidCallback onLogout;
  const AccountTab({super.key, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    final user = AppState.currentUser;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: kRed,
              child: Text(
                user != null && user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? '',
                    style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: kCardBg,
            border: Border.all(color: user?.isPremium == true ? Colors.amber : Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user?.isPremium == true ? '⭐ VIP Member (Active)' : 'Free Plan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: user?.isPremium == true ? Colors.amber : Colors.white70),
              ),
              if (user?.isPremium != true)
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Payment gateway connect ho raha hai...')),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: kRed),
                  child: const Text('Upgrade'),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ListTile(
          leading: const Icon(Icons.history),
          title: const Text('Watch History'),
          trailing: Text('${AppState.watchHistory.length} watched',
              style: const TextStyle(color: Colors.white54)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('My List'),
          trailing: Text('${AppState.myList.length} items',
              style: const TextStyle(color: Colors.white54)),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          onTap: onLogout,
        ),
      ],
    );
  }
}
