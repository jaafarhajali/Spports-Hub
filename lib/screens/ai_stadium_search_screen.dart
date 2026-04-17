import 'package:flutter/material.dart';
import 'package:first_attempt/services/ai_service.dart';
import 'package:first_attempt/utils/logger.dart';

class AiStadiumSearchScreen extends StatefulWidget {
  const AiStadiumSearchScreen({super.key});

  @override
  State<AiStadiumSearchScreen> createState() => _AiStadiumSearchScreenState();
}

class _AiStadiumSearchScreenState extends State<AiStadiumSearchScreen> {
  final _aiService = AiService();
  final _controller = TextEditingController();

  bool _loading = false;
  List<Map<String, dynamic>> _results = [];
  Map<String, dynamic>? _parsed;
  String? _error;

  static const List<String> _examples = [
    'turf stadium in luanda under 50k for 10+ players',
    'cheapest stadium open in the evening',
    'big stadium for at least 20 players in tripoli',
    'stadium available sunday morning under 100k',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty || _loading) return;
    setState(() {
      _loading = true;
      _error = null;
      _results = [];
      _parsed = null;
    });
    try {
      final res = await _aiService.searchStadiums(query.trim());
      final data = (res['data'] as List?) ?? [];
      final parsed = res['parsed'] as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        _results = data.cast<Map<String, dynamic>>();
        _parsed = parsed;
      });
    } catch (e, s) {
      AppLogger.error('AI search failed', error: e, stack: s);
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.auto_awesome, size: 20),
            SizedBox(width: 8),
            Text('AI Stadium Search'),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Describe the stadium you want in plain English.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_loading,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _search,
                    decoration: const InputDecoration(
                      hintText: 'e.g. turf in luanda under 50k for 10 players',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: _loading ? null : () => _search(_controller.text),
                  icon: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(_loading ? '...' : 'Search'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _examples
                  .map(
                    (ex) => ActionChip(
                      label: Text(ex, style: const TextStyle(fontSize: 11)),
                      onPressed: _loading
                          ? null
                          : () {
                              _controller.text = ex;
                              _search(ex);
                            },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            if (_parsed != null) _ParsedFiltersCard(parsed: _parsed!),
            if (_error != null)
              Card(
                color: Colors.red.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!, style: const TextStyle(color: Colors.red))),
                    ],
                  ),
                ),
              ),
            if (!_loading && _parsed != null && _results.isEmpty && _error == null)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: Text('No stadiums matched. Try a different query.')),
              ),
            ..._results.map((s) => _StadiumResultCard(stadium: s)),
          ],
        ),
      ),
    );
  }
}

class _ParsedFiltersCard extends StatelessWidget {
  final Map<String, dynamic> parsed;
  const _ParsedFiltersCard({required this.parsed});

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    void add(String label, dynamic value) {
      if (value == null || (value is String && value.isEmpty)) return;
      chips.add(Chip(label: Text('$label: $value', style: const TextStyle(fontSize: 12))));
    }

    add('Location', parsed['location']);
    if (parsed['priceMax'] != null) add('Max price', parsed['priceMax']);
    if (parsed['priceMin'] != null) add('Min price', parsed['priceMin']);
    if (parsed['minPlayers'] != null) add('Min players', parsed['minPlayers']);
    add('Open at', parsed['openAt']);
    add('Day', parsed['dayOfWeek']);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Interpreted as',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            if (chips.isEmpty)
              const Text('No specific filters — showing everything.',
                  style: TextStyle(color: Colors.grey))
            else
              Wrap(spacing: 6, runSpacing: 6, children: chips),
          ],
        ),
      ),
    );
  }
}

class _StadiumResultCard extends StatelessWidget {
  final Map<String, dynamic> stadium;
  const _StadiumResultCard({required this.stadium});

  @override
  Widget build(BuildContext context) {
    final name = stadium['name']?.toString() ?? 'Stadium';
    final location = stadium['location']?.toString() ?? '';
    final price = stadium['pricePerMatch'];
    final maxPlayers = stadium['maxPlayers'];
    final hours = stadium['workingHours'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: const Icon(Icons.sports_soccer, size: 36),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (location.isNotEmpty) Text('📍 $location'),
            Row(
              children: [
                if (price != null) Text('💰 ${price.toString()} '),
                if (maxPlayers != null) Text(' · 👥 up to $maxPlayers'),
              ],
            ),
            if (hours != null) Text('🕐 ${hours['start']} – ${hours['end']}'),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
