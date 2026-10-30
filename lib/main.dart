import 'package:flutter/material.dart';

const kRed = Color(0xFFE50914);
const kBg = Color(0xFF0B0B0F);

class Movie {
  final String title, genre, year;
  const Movie(this.title, this.genre, this.year);
}

const movies = [
  Movie('Dark Horizon', 'Thriller', '2024'),
  Movie('Last Kingdom', 'Action', '2023'),
  Movie('Love in Paris', 'Romance', '2024'),
  Movie('Laugh Riot', 'Comedy', '2022'),
  Movie('The Silent House', 'Horror', '2023'),
  Movie('Star Voyage', 'Sci-Fi', '2025'),
  Movie('Family Time', 'Family', '2021'),
  Movie('Broken Roads', 'Drama', '2024'),
];

const categories = [
  'Action', 'Comedy', 'Drama', 'Romance',
  'Thriller', 'Horror', 'Sci-Fi', 'Family'
];

const palette = [
  Color(0xFF8B1E3F), Color(0xFF1E5F8B), Color(0xFF2E7D32),
  Color(0xFF6A1B9A), Color(0xFFB8620B), Color(0xFF00695C),
];

void soon(BuildContext c) {
  ScaffoldMessenger.of(c)
      .showSnackBar(const SnackBar(content: Text('Coming soon')));
}

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
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const MainShell()));
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('CINEVORA FILMS',
            style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: 3,
                color: kRed)),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;
  final pages = const [HomeTab(), SearchTab(), CategoriesTab(), AccountTab()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('CINEVORA',
            style: TextStyle(color: kRed, fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () => soon(context)),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(icon: Icon(Icons.grid_view_outlined), selectedIcon: Icon(Icons.grid_view), label: 'Categories'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Account'),
        ],
      ),
    );
  }
}

class PosterCard extends StatelessWidget {
  final Movie movie;
  final double width, height;
  const PosterCard(
      {super.key, required this.movie, this.width = 110, this.height = 160});
  @override
  Widget build(BuildContext context) {
    final c = palette[movie.title.length % palette.length];
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => MovieDetail(movie: movie))),
      child: Container(
        width: width,
        height: height,
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.all(8),
        alignment: Alignment.bottomLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [c, Colors.black]),
        ),
        child: Text(movie.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      ),
    );
  }
}

class HomeTab extends StatelessWidget {
  const HomeTab({super.key});
  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => MovieDetail(movie: movies[0]))),
          child: Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            alignment: Alignment.bottomLeft,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF8B1E3F), Colors.black]),
            ),
            child: const Text('Dark Horizon\nFeatured',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          ),
        ),
        for (final t in ['Trending Now', 'New Releases', 'Web Series'])
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(t,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: movies.length,
                    itemBuilder: (_, i) => PosterCard(movie: movies[i]),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class SearchTab extends StatefulWidget {
  const SearchTab({super.key});
  @override
  State<SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<SearchTab> {
  String q = '';
  @override
  Widget build(BuildContext context) {
    final results = movies
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
                      leading: Container(
                        width: 44,
                        height: 60,
                        decoration: BoxDecoration(
                            color: palette[m.title.length % palette.length],
                            borderRadius: BorderRadius.circular(6)),
                      ),
                      title: Text(m.title),
                      subtitle: Text('${m.genre} • ${m.year}'),
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

class CategoriesTab extends StatelessWidget {
  const CategoriesTab({super.key});
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 2,
      children: [
        for (final c in categories)
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => CategoryScreen(name: c))),
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: palette[c.length % palette.length],
                  borderRadius: BorderRadius.circular(12)),
              child: Text(c,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ),
      ],
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final String name;
  const CategoryScreen({super.key, required this.name});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: GridView.count(
        crossAxisCount: 3,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 10,
        childAspectRatio: 0.65,
        children: [
          for (final m in movies)
            PosterCard(movie: m, width: double.infinity, height: double.infinity),
        ],
      ),
    );
  }
}

class MovieDetail extends StatelessWidget {
  final Movie movie;
  const MovieDetail({super.key, required this.movie});
  @override
  Widget build(BuildContext context) {
    final c = palette[movie.title.length % palette.length];
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: ListView(
        children: [
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [c, kBg]),
            ),
            child: const Center(
                child: Icon(Icons.play_circle_fill, size: 72, color: Colors.white70)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(movie.title,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text('${movie.year} • ${movie.genre} • HD',
                    style: const TextStyle(color: Colors.white60)),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => soon(context),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Play'),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => soon(context),
                        icon: const Icon(Icons.add),
                        label: const Text('My List'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => soon(context),
                        icon: const Icon(Icons.download),
                        label: const Text('Download'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                    'Yahan movie ki story likhi aayegi. Ye abhi dummy text hai.',
                    style: TextStyle(color: Colors.white70, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AccountTab extends StatelessWidget {
  const AccountTab({super.key});

  Widget tile(BuildContext context, IconData icon, String title,
      {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap ?? () => soon(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Row(
          children: [
            CircleAvatar(
                radius: 32,
                backgroundColor: kRed,
                child: Icon(Icons.person, size: 36)),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Guest User',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('Login karke apni list sync karo',
                    style: TextStyle(color: Colors.white60)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
              onPressed: () => soon(context),
              child: const Text('Login / Sign up')),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
                colors: [Color(0xFFE50914), Color(0xFF8B0000)]),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Go Premium',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              const Text('No ads • HD streaming • Downloads'),
              const SizedBox(height: 12),
              ElevatedButton(
                  onPressed: () => soon(context),
                  child: const Text('Subscribe')),
            ],
          ),
        ),
        const SizedBox(height: 8),
        tile(context, Icons.bookmark_border, 'My List'),
        tile(context, Icons.download_outlined, 'Downloads'),
        tile(context, Icons.history, 'Watch History'),
        tile(context, Icons.settings_outlined, 'Settings',
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()))),
        tile(context, Icons.help_outline, 'Help & Support'),
        tile(context, Icons.info_outline, 'About CineVora'),
      ],
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool wifiOnly = true, autoplay = true, notif = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          SwitchListTile(
              title: const Text('Download only on Wi-Fi'),
              value: wifiOnly,
              onChanged: (v) => setState(() => wifiOnly = v)),
          SwitchListTile(
              title: const Text('Autoplay next episode'),
              value: autoplay,
              onChanged: (v) => setState(() => autoplay = v)),
          SwitchListTile(
              title: const Text('Notifications'),
              value: notif,
              onChanged: (v) => setState(() => notif = v)),
        ],
      ),
    );
  }
}
