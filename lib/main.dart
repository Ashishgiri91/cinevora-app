import 'package:flutter/material.dart';

void main() => runApp(const CineVoraApp());

class CineVoraApp extends StatelessWidget {
  const CineVoraApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CineVora Films',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0B0F),
        colorScheme: const ColorScheme.dark(primary: Color(0xFFE50914)),
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
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
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
                color: Color(0xFFE50914))),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('CINEVORA',
            style: TextStyle(
                color: Color(0xFFE50914), fontWeight: FontWeight.w900)),
      ),
      body: ListView(
        children: [
          Container(
            height: 220,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: Colors.white10, borderRadius: BorderRadius.circular(16)),
            child: const Center(child: Text('Featured Banner')),
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
                      itemCount: 8,
                      itemBuilder: (_, i) => Container(
                        width: 110,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(10)),
                        child: Center(child: Text('Movie ${i + 1}')),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
