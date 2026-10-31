import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

// Live cPanel API URL
const String kApiBaseUrl = 'http://cinevorafilms.in/api/index.php';

const kRed = Color(0xFFE50914);
const kBg = Color(0xFF0B0B0F);
const kCardBg = Color(0xFF16161F);

// User Session Data Model
class UserModel {
  final int id;
  final String name;
  final String email;
  final bool isPremium;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.isPremium,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      isPremium: json['is_premium'] == 1 || json['is_premium'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'is_premium': isPremium ? 1 : 0,
  };
}

// Movie Data Model
class Movie {
  final String id;
  final String title;
  final String category;
  final String year;
  final String poster;
  final String banner;
  final String videoUrl;
  final String description;
  final bool isFeatured;
  final bool isPremium;

  Movie({
    required this.id,
    required this.title,
    required this.category,
    required this.year,
    required this.poster,
    required this.banner,
    required this.videoUrl,
    required this.description,
    required this.isFeatured,
    required this.isPremium,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      id: json['id'].toString(),
      title: json['title'] ?? '',
      category: json['category'] ?? 'General',
      year: json['year'] ?? '2026',
      poster: json['poster'] != null && json['poster'].toString().isNotEmpty
          ? json['poster'].toString()
          : 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600',
      banner: json['banner'] != null && json['banner'].toString().isNotEmpty
          ? json['banner'].toString()
          : 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200',
      videoUrl: json['video_url'] ?? '',
      description: json['description'] ?? 'No description provided.',
      isFeatured: json['is_featured'] == 1 || json['is_featured'] == '1',
      isPremium: json['is_premium'] == 1 || json['is_premium'] == '1',
    );
  }
}

// Global Runtime State
class AppState {
  static UserModel? currentUser;
  static List<Movie> movies = [];
  static Movie? featuredMovie;
  static List<String> categories = [];
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

// 1. SPLASH SCREEN (Auto-checks saved login)
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
    final savedData = prefs.getString('user_session');

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    if (savedData != null && savedData.isNotEmpty) {
      final jsonMap = jsonDecode(savedData);
      AppState.currentUser = UserModel.fromJson(jsonMap);
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

// 2. AUTH SCREEN (Strict Real Verification via Database)
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
        const SnackBar(content: Text('Sabhi details bharna zaroori hai!')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final targetUrl = '$kApiBaseUrl?action=${isLogin ? "login" : "signup"}';
      final response = await http.post(
        Uri.parse(targetUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': pass,
        }),
      );

      final result = jsonDecode(response.body);

      if (result['status'] == 'success') {
        final user = UserModel.fromJson(result['user']);
        AppState.currentUser = user;

        // Save session locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_session', jsonEncode(user.toJson()));

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

// 3. MAIN SHELL (App Container)
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  bool isFeedLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFeed();
  }

  Future<void> _fetchFeed() async {
    try {
      final res = await http.get(Uri.parse('$kApiBaseUrl?action=get_feed'));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['status'] == 'success') {
          final List trendingRaw = data['trending'] ?? [];
          final List catsRaw = data['categories'] ?? [];

          AppState.movies = trendingRaw.map((e) => Movie.fromJson(e)).toList();
          if (data['featured'] != null) {
            AppState.featuredMovie = Movie.fromJson(data['featured']);
          } else if (AppState.movies.isNotEmpty) {
            AppState.featuredMovie = AppState.movies.first;
          }
          AppState.categories = catsRaw.map((e) => e['name'].toString()).toList();
        }
      }
    } catch (_) {}
    if (mounted) setState(() => isFeedLoading = false);
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_session');
    AppState.currentUser = null;
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const AuthScreen()));
  }

  @override
  Widget build(BuildContext context) {
    if (isFeedLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: kRed)),
      );
    }

    final pages = [
      const HomeTab(),
      const SearchTab(),
      const CategoriesTab(),
      AccountTab(onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CINEVORA',
            style: TextStyle(
                color: kRed, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
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

// 4. POSTER CARD
class PosterCard extends StatelessWidget {
  final Movie movie;
  final double width, height;
  const PosterCard({
    super.key,
    required this.movie,
    this.width = 110,
    this.height = 160,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => MovieDetail(movie: movie))),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: kCardBg,
          image: DecorationImage(
            image: NetworkImage(movie.poster),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.transparent, Colors.black87],
            ),
          ),
          padding: const EdgeInsets.all(8),
          alignment: Alignment.bottomLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (movie.isPremium)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                      color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                  child: const Text('VIP',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.black)),
                ),
              Text(
                movie.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 5. HOME TAB
class HomeTab extends StatelessWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context) {
    final feat = AppState.featuredMovie;

    return ListView(
      children: [
        if (feat != null)
          GestureDetector(
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => MovieDetail(movie: feat))),
            child: Container(
              height: 230,
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: kCardBg,
                image: DecorationImage(
                  image: NetworkImage(feat.banner),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black]),
                ),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: kRed, borderRadius: BorderRadius.circular(6)),
                      child: const Text('FEATURED NOW',
                          style: TextStyle(
                              fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 6),
                    Text(feat.title,
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w900)),
                    Text('${feat.category} • ${feat.year}',
                        style: const TextStyle(color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: const Text('Latest Movies & Series',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 160,
          child: AppState.movies.isEmpty
              ? const Center(child: Text('Abhi koi movie upload nahi hui hai.'))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(left: 16),
                  itemCount: AppState.movies.length,
                  itemBuilder: (_, i) => PosterCard(movie: AppState.movies[i]),
                ),
        ),
      ],
    );
  }
}

// 6. SEARCH TAB
class SearchTab extends StatefulWidget {
  const SearchTab({super.key});

  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String q = '';

  @override
  Widget build(BuildContext context) {
    final results = AppState.movies
        .where((m) =>
            m.title.toLowerCase().contains(q.toLowerCase()) ||
            m.category.toLowerCase().contains(q.toLowerCase()))
        .toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            onChanged: (v) => setState(() => q = v),
            decoration: InputDecoration(
              hintText: 'Search movies, series...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: kCardBg,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
            ),
          ),
        ),
        Expanded(
          child: results.isEmpty
              ? const Center(child: Text('Kuch nahi mila'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final m = results[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(m.poster,
                            width: 50, height: 70, fit: BoxFit.cover),
                      ),
                      title: Text(m.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.category} • ${m.year}'),
                      trailing: const Icon(Icons.play_circle_outline, color: kRed),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => MovieDetail(movie: m))),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// 7. CATEGORIES TAB
class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: AppState.categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, i) {
        final cat = AppState.categories[i];
        return GestureDetector(
          onTap: () {
            final filtered = AppState.movies
                .where((m) => m.category.toLowerCase() == cat.toLowerCase())
                .toList();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: Text(cat)),
                  body: filtered.isEmpty
                      ? Center(child: Text('$cat me abhi koi content nahi hai.'))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.65,
                          ),
                          itemBuilder: (_, j) => PosterCard(
                              movie: filtered[j],
                              width: double.infinity,
                              height: double.infinity),
                        ),
                ),
              ),
            );
          },
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: kCardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(cat,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }
}

// 8. MOVIE DETAIL & VIDEO STREAM PLAYER
class MovieDetail extends StatefulWidget {
  final Movie movie;
  const MovieDetail({super.key, required this.movie});

  @override
  State<MovieDetail> createState() => _MovieDetailState();
}

class _MovieDetailState extends State<MovieDetail> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isLocked = false;

  @override
  void initState() {
    super.initState();
    // Check VIP permission
    if (widget.movie.isPremium && (AppState.currentUser?.isPremium != true)) {
      isLocked = true;
    } else {
      _initPlayer();
      _trackWatch();
    }
  }

  void _trackWatch() {
    if (AppState.currentUser != null) {
      http.post(
        Uri.parse('$kApiBaseUrl?action=track_watch'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': AppState.currentUser!.id,
          'movie_id': widget.movie.id,
        }),
      );
      if (!AppState.watchHistory.contains(widget.movie.title)) {
        AppState.watchHistory.add(widget.movie.title);
      }
    }
  }

  Future<void> _initPlayer() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: true,
      looping: false,
      aspectRatio: _videoController.value.aspectRatio,
      materialProgressColors: ChewieProgressColors(
        playedColor: kRed,
        handleColor: kRed,
        backgroundColor: Colors.grey,
        bufferedColor: Colors.white24,
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    if (!isLocked) {
      _videoController.dispose();
      _chewieController?.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = AppState.myList.contains(widget.movie.id);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        children: [
          Container(
            height: 240,
            color: Colors.black,
            child: isLocked
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.lock, size: 50, color: Colors.amber),
                        const SizedBox(height: 10),
                        const Text('Yeh Content VIP Members ke liye hai!',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content: Text(
                                      'Account me jakar Subscription Upgrade karein.')),
                            );
                          },
                          style:
                              ElevatedButton.styleFrom(backgroundColor: kRed),
                          child: const Text('Upgrade Plan'),
                        ),
                      ],
                    ),
                  )
                : (_chewieController != null &&
                        _chewieController!
                            .videoPlayerController.value.isInitialized
                    ? Chewie(controller: _chewieController!)
                    : const Center(
                        child: CircularProgressIndicator(color: kRed))),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.movie.title,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('${widget.movie.year} • ${widget.movie.category} • HD',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            if (isSaved) {
                              AppState.myList.remove(widget.movie.id);
                            } else {
                              AppState.myList.add(widget.movie.id);
                            }
                          });
                        },
                        icon: Icon(isSaved ? Icons.check : Icons.add,
                            color: isSaved ? Colors.green : Colors.white),
                        label: Text(isSaved ? 'In My List' : 'My List'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Storyline',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(widget.movie.description,
                    style: const TextStyle(
                        color: Colors.white70, height: 1.5, fontSize: 14)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 9. ACCOUNT TAB
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
                user != null && user.name.isNotEmpty
                    ? user.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'User',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
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
            border: Border.all(
                color: user?.isPremium == true ? Colors.amber : Colors.white12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                user?.isPremium == true ? '⭐ VIP Member (Active)' : 'Free Plan',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: user?.isPremium == true
                        ? Colors.amber
                        : Colors.white70),
              ),
              if (user?.isPremium != true)
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text(
                              'Admin panel se apna VIP status active karwayein.')),
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
        ),
        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('My List'),
          trailing: Text('${AppState.myList.length} saved',
              style: const TextStyle(color: Colors.white54)),
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
