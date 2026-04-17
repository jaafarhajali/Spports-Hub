import 'package:flutter/material.dart';
import 'package:first_attempt/services/skills_service.dart';
import 'package:first_attempt/utils/logger.dart';

class SkillsEditorScreen extends StatefulWidget {
  const SkillsEditorScreen({super.key});

  @override
  State<SkillsEditorScreen> createState() => _SkillsEditorScreenState();
}

class _SkillsEditorScreenState extends State<SkillsEditorScreen> {
  final _service = SkillsService();
  final _bioController = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  String? _error;

  PlayerSkills _skills = PlayerSkills();

  static const _positions = [
    ('goalkeeper', 'Goalkeeper', Icons.sports_kabaddi),
    ('defender', 'Defender', Icons.shield),
    ('midfielder', 'Midfielder', Icons.sync_alt),
    ('forward', 'Forward', Icons.sports_soccer),
  ];

  static const _feet = [
    ('left', 'Left'),
    ('right', 'Right'),
    ('both', 'Both'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final s = await _service.getMine();
      if (!mounted) return;
      setState(() {
        _skills = s;
        _bioController.text = s.bio;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = _skills.copyWith(bio: _bioController.text.trim());
      final saved = await _service.update(updated);
      if (!mounted) return;
      setState(() {
        _skills = saved;
        _bioController.text = saved.bio;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Skills saved')),
      );
    } catch (e, s) {
      AppLogger.error('Skills save failed', error: e, stack: s);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _introCard(),
                    const SizedBox(height: 16),
                    _sectionLabel('Position'),
                    _positionGrid(),
                    const SizedBox(height: 16),
                    _sectionLabel('Skill level (1–10)'),
                    _skillSlider(),
                    const SizedBox(height: 16),
                    _sectionLabel('Preferred foot'),
                    _footRow(),
                    const SizedBox(height: 16),
                    _sectionLabel('Short bio (optional)'),
                    _bioField(),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _saving ? null : _save,
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_saving ? 'Saving...' : 'Save skills'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _introCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline, color: Colors.blue),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Team leaders use this profile to find complementary players. '
                'Fill in what you play — you can update it anytime.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
      );

  Widget _positionGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 3.2,
      children: _positions.map((p) {
        final value = p.$1;
        final selected = _skills.position == value;
        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => setState(() {
            _skills = _skills.copyWith(
              position: selected ? null : value,
              clearPosition: selected,
            );
          }),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: selected
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                  : null,
              border: Border.all(
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).dividerColor,
                width: selected ? 1.5 : 1,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(p.$3, size: 20, color: selected ? Theme.of(context).colorScheme.primary : null),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p.$2,
                    style: TextStyle(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _skillSlider() {
    final level = _skills.skillLevel ?? 5;
    return Row(
      children: [
        Expanded(
          child: Slider(
            value: level.toDouble(),
            min: 1,
            max: 10,
            divisions: 9,
            label: '$level',
            onChanged: (v) => setState(() {
              _skills = _skills.copyWith(skillLevel: v.round());
            }),
          ),
        ),
        SizedBox(
          width: 36,
          child: Text(
            '${_skills.skillLevel ?? "—"}',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _footRow() {
    return Row(
      children: _feet.map((f) {
        final value = f.$1;
        final selected = _skills.preferredFoot == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: OutlinedButton(
              onPressed: () => setState(() {
                _skills = _skills.copyWith(
                  preferredFoot: selected ? null : value,
                  clearPreferredFoot: selected,
                );
              }),
              style: OutlinedButton.styleFrom(
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
                    : null,
                side: BorderSide(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).dividerColor,
                  width: selected ? 1.5 : 1,
                ),
              ),
              child: Text(f.$2),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _bioField() {
    return TextField(
      controller: _bioController,
      maxLength: 300,
      maxLines: 3,
      decoration: const InputDecoration(
        hintText: 'Tell team leaders about your strengths...',
        border: OutlineInputBorder(),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorRetry({required this.message, required this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
