import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/services/firebase_service.dart';
import '../../../presentation/providers/providers.dart';
import '../../data/admin_providers.dart';

class BroadcastScreen extends ConsumerStatefulWidget {
  const BroadcastScreen({super.key});

  @override
  ConsumerState<BroadcastScreen> createState() => _BroadcastScreenState();
}

class _BroadcastScreenState extends ConsumerState<BroadcastScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _busy = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_title.text.trim().isEmpty || _body.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Title and message are required')),
      );
      return;
    }
    if (!FirebaseService.isInitialized) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Firebase is not configured. See README.')),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send broadcast?'),
        content: Text(
          'Every customer will see "${_title.text.trim()}" the next time '
          'they open the app. Send now?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Send')),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _busy = true);
    try {
      final user = ref.read(currentUserProvider);
      await ref.read(adminRepositoryProvider).sendBroadcast(
            authorName: user?.fullName ?? 'Admin',
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Broadcast sent'),
            backgroundColor: AppColors.success),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Broadcast')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.info.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.info.withOpacity(0.2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.info),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Use this to announce new stock, promotions or store '
                    'updates. Every customer will receive it.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'e.g. New stock arrived!',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _body,
            textCapitalization: TextCapitalization.sentences,
            maxLines: 6,
            decoration: const InputDecoration(
              labelText: 'Message',
              alignLabelWithHint: true,
              hintText:
                  'e.g. Fresh garri, beans and rice are now available. '
                  'Order before 4pm for same-day delivery.',
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _busy ? null : _send,
            icon: _busy
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            label: const Text('Send to all customers'),
          ),
        ],
      ),
    );
  }
}
