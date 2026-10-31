import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

const kRed = Color(0xFFE50914);
const kBg = Color(0xFF0B0B0F);
const kCardBg = Color(0xFF16161F);

// User Session Model
class UserModel {
  String name;
  String email;
  bool isPremium;
  UserModel({required this.name, required this.email, this.isPremium = false});
}

// Global App State (Zero Dummy, Real State)
class AppState {
  static UserModel? currentUser;
  static Set<String> myList = {};
  static List<Movie> movies = [
    Movie(
      id: '1',
      title: 'Dark Horizon',
      genre: 'Thriller',
      year: '2024',
      posterUrl: 'https://images.unsplash.com/photo-1536440136628-849c177e76a1?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
      description: 'Ek gupt mission jo waqt ke sath sabse khatarnak thriller me badal jata hai.',
    ),
    Movie(
      id: '2',
      title: 'Last Kingdom',
      genre: 'Action',
      year: '2023',
      posterUrl: 'https://images.unsplash.com/photo-1579783900882-c0d3dad7b119?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1509198397868-475647b2a1e5?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4',
      description: 'Yuddh, satta aur samman ki aisi jung jisme sirf ek vijeta hoga.',
    ),
    Movie(
      id: '3',
      title: 'Love in Paris',
      genre: 'Romance',
      year: '2024',
      posterUrl: 'https://images.unsplash.com/photo-1502602898657-3e91760cbb34?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4',
      description: 'Paris ki khoobsurat sadkon par shuru hui do dilon ki kahani.',
    ),
    Movie(
      id: '4',
      title: 'Laugh Riot',
      genre: 'Comedy',
      year: '2022',
      posterUrl: 'https://images.unsplash.com/photo-1514306191717-452ec28c7814?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerEscapes.mp4',
      description: 'Haso bina ruke! Chaar doston ki aisi masti jo sabko deewana bana de.',
    ),
    Movie(
      id: '5',
      title: 'The Silent House',
      genre: 'Horror',
      year: '2023',
      posterUrl: 'https://images.unsplash.com/photo-1509248961158-e54f6934749c?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1518709268805-4e9042af9f23?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerFun.mp4',
      description: 'Ek purani haveli jahan raat hote hi sannata bolne lagta hai.',
    ),
    Movie(
      id: '6',
      title: 'Star Voyage',
      genre: 'Sci-Fi',
      year: '2025',
      posterUrl: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=600&auto=format&fit=crop&q=80',
      bannerUrl: 'https://images.unsplash.com/photo-1506703719100-a0f3a48c0f86?w=1200&auto=format&fit=crop&q=80',
      videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerJoyBlazes.mp4',
      description: 'Anthariksh ke paar naye grahon ki khoj me nikla ek aakhri dasta.',
    ),
  ];
}

class Movie {
  final String id, title, genre, year, posterUrl, bannerUrl, videoUrl, description;
  const Movie({
    required this.id,
    required this.title,
    required this.genre,
    required this.year,
    required this.posterUrl,
    required this.bannerUrl,
    required this.videoUrl,
    required this.description,
  });
}

const categories = ['Action', 'Comedy', 'Drama', 'Romance', 'Thriller', 'Horror', 'Sci-Fi'];

void main() => runApp(const CineVoraApp());

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

// 1. SPLASH SCREEN (Auto-routes to Login if not authenticated)
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      if (AppState.currentUser == null) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      } else {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const MainShell()));
      }
    });
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

// 2. AUTH SCREEN (Login / Signup / Google Login / Guest)
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool isLogin = true;
  final emailController = TextEditingController();
  final passController = TextEditingController();
  final nameController = TextEditingController();

  void doAuth() {
    final email = emailController.text.trim();
    final name = isLogin
        ? (email.contains('@') ? email.split('@')[0] : 'CineVora User')
        : nameController.text.trim();

    if (email.isEmpty || passController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kripya Email aur Password daalein!')),
      );
      return;
    }

    setState(() {
      AppState.currentUser = UserModel(
        name: name.isEmpty ? 'User' : name,
        email: email,
        isPremium: false,
      );
    });

    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  void doGoogleAuth() {
    setState(() {
      AppState.currentUser = UserModel(
        name: 'Google User',
        email: 'user@gmail.com',
        isPremium: false,
      );
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
  }

  void skipAsGuest() {
    setState(() {
      AppState.currentUser = UserModel(
        name: 'Guest User',
        email: 'guest@cinevora.in',
        isPremium: false,
      );
    });
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const MainShell()));
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
                    ? 'Apne account me login karein aur movies enjoy karein'
                    : 'Naya account banakar unlimited movies dekhein',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 30),
              if (!isLogin) ...[
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.person_outline),
                    hintText: 'Aapka Naam',
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
                onPressed: doAuth,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  isLogin ? 'Log In' : 'Sign Up',
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: doGoogleAuth,
                icon: const Icon(Icons.g_mobiledata, size: 28, color: Colors.white),
                label: const Text('Continue with Google',
                    style: TextStyle(color: Colors.white, fontSize: 15)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(isLogin ? "Naya account chahiye? " : "Pehle se account hai? "),
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
              const SizedBox(height: 24),
              TextButton(
                onPressed: skipAsGuest,
                child: const Text('Guest bankar dekhein →',
                    style: TextStyle(color: Colors.white54)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 3. MAIN NAVIGATION SHELL
class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeTab(),
      const SearchTab(),
      const CategoriesTab(),
      AccountTab(onLogout: () {
        setState(() {
          AppState.currentUser = null;
        });
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AuthScreen()));
      }),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('CINEVORA',
            style: TextStyle(color: kRed, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
        actions: [
          IconButton(
            icon: const Icon(Icons.card_membership, color: Colors.amber),
            onPressed: () => showPremiumDialog(context),
          ),
        ],
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

// 4. POSTER CARD WIDGET
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
          image: DecorationImage(
            image: NetworkImage(movie.posterUrl),
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
          child: Text(
            movie.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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
    final featured = AppState.movies.first;

    return ListView(
      children: [
        // Featured Big Banner
        GestureDetector(
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => MovieDetail(movie: featured))),
          child: Container(
            height: 230,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              image: DecorationImage(
                image: NetworkImage(featured.bannerUrl),
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
                  Text(featured.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  Text('${featured.genre} • ${featured.year}',
                      style: const TextStyle(color: Colors.white70)),
                ],
              ),
            ),
          ),
        ),

        // Movie Rows
        for (final rowName in ['Trending Now', 'New Releases', 'Web Series'])
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(rowName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: AppState.movies.length,
                    itemBuilder: (_, i) => PosterCard(movie: AppState.movies[i]),
                  ),
                ),
              ],
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
            m.genre.toLowerCase().contains(q.toLowerCase()))
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
              ? const Center(child: Text('Koi movie nahi mili'))
              : ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final m = results[i];
                    return ListTile(
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(m.posterUrl,
                            width: 50, height: 70, fit: BoxFit.cover),
                      ),
                      title: Text(m.title,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${m.genre} • ${m.year}'),
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
      itemCount: categories.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 2.2,
      ),
      itemBuilder: (_, i) {
        final cat = categories[i];
        return GestureDetector(
          onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CategoryScreen(categoryName: cat))),
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

// 8. CATEGORY SCREEN (Displays movies filtered by genre)
class CategoryScreen extends StatelessWidget {
  final String categoryName;
  const CategoryScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final filtered = AppState.movies
        .where((m) => m.genre.toLowerCase() == categoryName.toLowerCase())
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text(categoryName)),
      body: filtered.isEmpty
          ? Center(child: Text('$categoryName me abhi koi content nahi hai.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (_, i) => PosterCard(
                  movie: filtered[i],
                  width: double.infinity,
                  height: double.infinity),
            ),
    );
  }
}

// 9. MOVIE DETAIL & REAL VIDEO STREAMING PLAYER
class MovieDetail extends StatefulWidget {
  final Movie movie;
  const MovieDetail({super.key, required this.movie});

  @override
  State<MovieDetail> createState() => _MovieDetailState();
}

class _MovieDetailState extends State<MovieDetail> {
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.movie.videoUrl));
    await _videoController.initialize();
    _chewieController = ChewieController(
      videoPlayerController: _videoController,
      autoPlay: false,
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
    _videoController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSaved = AppState.myList.contains(widget.movie.id);

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: ListView(
        children: [
          // Real Video Player Box
          Container(
            height: 240,
            color: Colors.black,
            child: _chewieController != null &&
                    _chewieController!.videoPlayerController.value.isInitialized
                ? Chewie(controller: _chewieController!)
                : const Center(
                    child: CircularProgressIndicator(color: kRed),
                  ),
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
                Text('${widget.movie.year} • ${widget.movie.genre} • Ultra HD 4K',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          _chewieController?.play();
                        },
                        style: FilledButton.styleFrom(
                            backgroundColor: kRed,
                            padding: const EdgeInsets.symmetric(vertical: 12)),
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Play Now',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 10),
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
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isSaved
                                ? 'My List se hata diya gaya'
                                : 'My List me add ho gaya!'),
                            duration: const Duration(seconds: 1),
                          ));
                        },
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12)),
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

// 10. ACCOUNT TAB & VIP MANAGEMENT
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
                    fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.name ?? 'Guest User',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(user?.email ?? 'No email linked',
                    style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Premium Banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFF6B0000)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user?.isPremium == true ? 'VIP Active Member' : 'Go Premium',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(user?.isPremium == true
                  ? 'Sabhi movies & series unlimited unlocked hain'
                  : 'No ads • 4K streaming • Unlimited downloads'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => showPremiumDialog(context),
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black),
                child: Text(
                    user?.isPremium == true ? 'Manage Plan' : 'Subscribe Now'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        ListTile(
          leading: const Icon(Icons.bookmark_border),
          title: const Text('My List'),
          trailing: Text('${AppState.myList.length} items',
              style: const TextStyle(color: Colors.white54)),
          onTap: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const MyListScreen()));
          },
        ),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('About CineVora Films'),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'CineVora Films',
              applicationVersion: '1.0.0',
              children: const [
                Text('Original Movies, Series & Entertainment Platform.'),
              ],
            );
          },
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

// 11. MY LIST SCREEN
class MyListScreen extends StatelessWidget {
  const MyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final listMovies = AppState.movies
        .where((m) => AppState.myList.contains(m.id))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('My List')),
      body: listMovies.isEmpty
          ? const Center(child: Text('Aapki list abhi khali hai.'))
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listMovies.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.65,
              ),
              itemBuilder: (_, i) => PosterCard(
                  movie: listMovies[i],
                  width: double.infinity,
                  height: double.infinity),
            ),
    );
  }
}

// 12. PREMIUM SUBSCRIPTION DIALOG
void showPremiumDialog(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF16161F),
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('CineVora VIP Access',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.amber)),
            const SizedBox(height: 8),
            const Text(
                'Original series, full movies bina kisi rukawat ke dekhein.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                AppState.currentUser?.isPremium = true;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CineVora VIP Activate ho gaya!')),
                );
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: kRed,
                  padding: const EdgeInsets.symmetric(vertical: 14)),
              child: const Text('Get VIP for ₹199 / Month',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    },
  );
}
