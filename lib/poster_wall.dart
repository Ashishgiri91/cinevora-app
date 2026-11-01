import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:http/http.dart' as http;
import 'api.dart';

Future<List<List<String>>> fetchPosterRows() async {
  try {
    final uri = Uri.parse(baseUrl.replaceFirst('index.php', 'posters.php'));
    final res = await http.get(uri).timeout(const Duration(seconds: 12));
    final d = jsonDecode(res.body) as Map<String, dynamic>;
    final rows = <List<String>>[];
    for (final r in (d['rows'] as List)) {
      final list = (r['posters'] as List)
          .map((e) => '$e')
          .where((e) => e.startsWith('http'))
          .toList();
      if (list.isNotEmpty) rows.add(list);
    }
    return rows;
  } catch (_) {
    return [];
  }
}

class PosterWall extends StatefulWidget {
  const PosterWall({super.key});
  @override
  State<PosterWall> createState() => _PosterWallState();
}

class _PosterWallState extends State<PosterWall>
    with SingleTickerProviderStateMixin {
  static const rowCount = 6;
  static const tileH = 165.0;
  final List<ScrollController> _ctrls =
      List.generate(rowCount, (_) => ScrollController());
  late final Ticker _ticker;
  List<List<String>> _rows = [];

  static const _fallback = [
    Color(0xFF8B1E3F), Color(0xFF1E5F8B), Color(0xFF2E7D32),
    Color(0xFF6A1B9A), Color(0xFFB8620B), Color(0xFF00695C),
  ];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker((elapsed) {
      final t = elapsed.inMilliseconds / 1000.0;
      for (var i = 0; i < _ctrls.length; i++) {
        final c = _ctrls[i];
        if (c.hasClients) c.jumpTo(t * (22.0 + i * 6.0));
      }
    })..start();
    fetchPosterRows().then((r) {
      if (!mounted) return;
      setState(() => _rows = _balance(r));
    });
  }

  List<List<String>> _balance(List<List<String>> r) {
    if (r.isEmpty) return [];
    if (r.length >= 4) return r.take(rowCount).toList();
    final all = r.expand((e) => e).toList();
    return List.generate(5, (i) {
      return List.generate(
          all.length < 6 ? 6 : all.length, (j) => all[(j + i * 2) % all.length]);
    });
  }

  @override
  void dispose() {
    _ticker.dispose();
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _tile(List<String> urls, int k, int row) {
    final c = _fallback[(k + row) % _fallback.length];
    return Container(
      width: 110,
      margin: const EdgeInsets.all(8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [c, Colors.black]),
      ),
      child: urls.isEmpty
          ? null
          : Image.network(urls[k % urls.length],
              fit: BoxFit.cover,
              cacheWidth: 220,
              errorBuilder: (_, __, ___) => const SizedBox.shrink()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rows =
        _rows.isEmpty ? List.generate(5, (_) => <String>[]) : _rows;
    return ClipRect(
      child: Transform.rotate(
        angle: -0.12,
        child: Transform.scale(
          scale: 1.35,
          child: OverflowBox(
            minHeight: 0,
            maxHeight: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < rows.length; i++)
                  SizedBox(
                    height: tileH + 16,
                    child: ListView.builder(
                      controller: _ctrls[i],
                      reverse: i.isOdd,
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, k) => _tile(rows[i], k, i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
