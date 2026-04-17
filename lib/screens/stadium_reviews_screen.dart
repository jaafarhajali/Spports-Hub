import 'package:flutter/material.dart';
import 'package:first_attempt/auth_service.dart';
import 'package:first_attempt/services/review_service.dart';
import 'package:first_attempt/services/ai_service.dart';
import 'package:first_attempt/utils/logger.dart';

class StadiumReviewsScreen extends StatefulWidget {
  final String stadiumId;
  final String? stadiumName;

  const StadiumReviewsScreen({
    super.key,
    required this.stadiumId,
    this.stadiumName,
  });

  @override
  State<StadiumReviewsScreen> createState() => _StadiumReviewsScreenState();
}

class _StadiumReviewsScreenState extends State<StadiumReviewsScreen> {
  final _reviewService = ReviewService();
  final _aiService = AiService();
  final _authService = AuthService();

  List<Review> _reviews = [];
  Map<String, dynamic>? _aiSummary;
  String? _myUserId;
  bool _loading = true;
  bool _submitting = false;
  String? _error;

  int _rating = 5;
  final _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    _myUserId = await _authService.getUserId();
    await _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final reviews = await _reviewService.listForStadium(widget.stadiumId);
      Map<String, dynamic>? summary;
      try {
        summary = await _aiService.reviewSummary(widget.stadiumId);
      } catch (e) {
        // AI summary is optional — don't fail the whole screen.
        AppLogger.debug('Review summary unavailable', meta: {'error': e.toString()});
      }
      if (!mounted) return;
      setState(() {
        _reviews = reviews;
        _aiSummary = summary;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Review? get _myReview {
    if (_myUserId == null) return null;
    for (final r in _reviews) {
      if (r.user?.id == _myUserId) return r;
    }
    return null;
  }

  Future<void> _submit() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Write a comment before submitting')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await _reviewService.create(
        stadiumId: widget.stadiumId,
        rating: _rating,
        comment: text,
      );
      if (!mounted) return;
      _commentController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review posted')),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete review?'),
        content: const Text('This will remove your review.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _reviewService.delete(reviewId);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.stadiumName == null
        ? 'Reviews'
        : 'Reviews · ${widget.stadiumName}';

    return Scaffold(
      appBar: AppBar(title: Text(title, overflow: TextOverflow.ellipsis)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _ErrorRetry(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_aiSummary != null) _AiSummaryCard(summary: _aiSummary!),
                      _buildFormOrMyReview(),
                      const SizedBox(height: 16),
                      _buildList(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildFormOrMyReview() {
    final me = _myReview;
    if (me != null) {
      return Card(
        margin: const EdgeInsets.only(bottom: 12),
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('Your review',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _delete(me.id),
                    tooltip: 'Delete',
                  ),
                ],
              ),
              _StarsRow(rating: me.rating),
              const SizedBox(height: 6),
              Text(me.comment),
            ],
          ),
        ),
      );
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Leave a review',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _RatingPicker(
              value: _rating,
              onChanged: (v) => setState(() => _rating = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLength: 1000,
              maxLines: 3,
              enabled: !_submitting,
              decoration: const InputDecoration(
                hintText: 'Share what you liked or didn\'t...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send),
                label: Text(_submitting ? 'Posting...' : 'Post review'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final others = _reviews.where((r) => r.id != _myReview?.id).toList();
    if (others.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Text(
            _reviews.isEmpty ? 'No reviews yet. Be the first!' : 'Only your review here.',
            style: const TextStyle(color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: others.map((r) => _ReviewTile(review: r)).toList(),
    );
  }
}

class _StarsRow extends StatelessWidget {
  final int rating;
  const _StarsRow({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => Icon(
          i < rating ? Icons.star : Icons.star_border,
          color: Colors.amber.shade600,
          size: 18,
        ),
      ),
    );
  }
}

class _RatingPicker extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const _RatingPicker({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final n = i + 1;
        return IconButton(
          onPressed: () => onChanged(n),
          icon: Icon(
            n <= value ? Icons.star : Icons.star_border,
            color: Colors.amber.shade600,
            size: 32,
          ),
        );
      }),
    );
  }
}

class _ReviewTile extends StatelessWidget {
  final Review review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(radius: 14, child: Icon(Icons.person, size: 16)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    review.user?.username ?? 'Anonymous',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _StarsRow(rating: review.rating),
              ],
            ),
            const SizedBox(height: 8),
            Text(review.comment),
            const SizedBox(height: 6),
            Text(
              _fmtDate(review.createdAt),
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }
}

class _AiSummaryCard extends StatelessWidget {
  final Map<String, dynamic> summary;
  const _AiSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final pros = (summary['pros'] as List?)?.cast<String>() ?? [];
    final cons = (summary['cons'] as List?)?.cast<String>() ?? [];
    final avg = (summary['averageRating'] is num) ? (summary['averageRating'] as num).toDouble() : 0.0;
    final count = summary['count'] is num ? (summary['count'] as num).toInt() : 0;
    final overview = summary['summary']?.toString() ?? '';

    if (count == 0) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                const SizedBox(width: 6),
                const Text('AI summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
                const Spacer(),
                Icon(Icons.star, size: 16, color: Colors.amber.shade600),
                Text(' ${avg.toStringAsFixed(1)} · $count'),
              ],
            ),
            if (overview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(overview, style: const TextStyle(fontStyle: FontStyle.italic)),
            ],
            if (pros.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Loved:',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.green)),
              ...pros.map((p) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• $p'),
                  )),
            ],
            if (cons.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('Complaints:',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Colors.red)),
              ...cons.map((c) => Padding(
                    padding: const EdgeInsets.only(left: 8, top: 2),
                    child: Text('• $c'),
                  )),
            ],
          ],
        ),
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
