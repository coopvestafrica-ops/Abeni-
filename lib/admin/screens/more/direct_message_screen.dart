import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/app_user.dart';
import '../../../data/services/firebase_service.dart';
import '../../data/admin_providers.dart';

/// Lets an admin search for a customer by name or phone and send them
/// a targeted push notification / inbox message.
class DirectMessageScreen extends ConsumerStatefulWidget {
  const DirectMessageScreen({super.key});

  @override
  ConsumerState<DirectMessageScreen> createState() =>
      _DirectMessageScreenState();
}

class _DirectMessageScreenState extends ConsumerState<DirectMessageScreen> {
  final _search = TextEditingController();
  final _title = TextEditingController();
  final _body = TextEditingController();

  AppUser? _selected;
  bool _sending = false;
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  List<AppUser> _filter(List<AppUser> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((u) {
      return u.fullName.toLowerCase().contains(q) ||
          u.phone.contains(q) ||
          u.email.toLowerCase().contains(q);
    }).toList();
  }

  void _select(AppUser user) {
    setState(() {
      _selected = user;
      _search.text = _label(user);
      _query = '';
    });
  }

  void _clear() {
    setState(() {
      _selected = null;
      _search.clear();
      _query = '';
    });
  }

  String _label(AppUser u) {
    final name = u.fullName.isNotEmpty ? u.fullName : 'Unknown';
    final phone = u.phone.isNotEmpty ? ' · ${u.phone}' : '';
    return '$name$phone';
  }

  Future<void> _send() async {
    final user = _selected;
    if (user == null) {
      _showSnack('Please select a customer first.');
      return;
    }
    if (_title.text.trim().isEmpty) {
      _showSnack('Title is required.');
      return;
    }
    if (_body.text.trim().isEmpty) {
      _showSnack('Message body is required.');
      return;
    }
    if (!FirebaseService.isInitialized) {
      _showSnack('Firebase is not configured. See README.');
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send message?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _PreviewRow(label: 'To', value: _label(user)),
            const SizedBox(height: 6),
            _PreviewRow(label: 'Title', value: _title.text.trim()),
            const SizedBox(height: 6),
            _PreviewRow(label: 'Message', value: _body.text.trim()),
            const SizedBox(height: 12),
            const Text(
              'The customer will receive a push notification and see it in '
              'their notification inbox.',
              style: TextStyle(
                  color: AppColors.textSecondary, fontSize: 12),
            ),
          ],
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

    setState(() => _sending = true);
    try {
      await ref.read(adminRepositoryProvider).sendDirectMessage(
            userId: user.id,
            title: _title.text.trim(),
            body: _body.text.trim(),
          );
      if (!mounted) return;
      _title.clear();
      _body.clear();
      _clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Message sent to ${user.fullName.isNotEmpty ? user.fullName : "customer"}'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _showSnack('Failed to send: $e', error: true);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allUsersAsync = ref.watch(adminAllUsersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Message a customer')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _InfoBanner(
                  icon: Icons.person_outline,
                  text:
                      'Search a customer by name or phone number, then compose '
                      'a personal message. They receive it as a push notification '
                      'and can read it in their Notifications tab.',
                ),
                const SizedBox(height: 20),
                const _SectionLabel('Recipient'),
                const SizedBox(height: 8),
                allUsersAsync.when(
                  data: (users) {
                    final filtered = _filter(users
                        .where((u) => u.role == UserRole.customer)
                        .toList());
                    return _CustomerPicker(
                      controller: _search,
                      selected: _selected,
                      suggestions: _query.isNotEmpty ? filtered : [],
                      onQueryChanged: (q) => setState(() => _query = q),
                      onSelect: _select,
                      onClear: _clear,
                      label: _label,
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('$e',
                      style: const TextStyle(color: AppColors.error)),
                ),
                if (_selected != null) ...[
                  const SizedBox(height: 8),
                  _SelectedCard(user: _selected!, onClear: _clear),
                ],
                const SizedBox(height: 20),
                const _SectionLabel('Message'),
                const SizedBox(height: 8),
                TextField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g. Your order is on the way!',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    hintText:
                        'e.g. Hi! We wanted to let you know that your delivery '
                        'is on its way. Expected arrival: 30 minutes.',
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 60),
                      child: Icon(Icons.message_outlined),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                _QuickMessageRow(
                  onTap: (title, body) {
                    _title.text = title;
                    _body.text = body;
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          _SendBar(sending: _sending, onSend: _send),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────── sub-widgets ──────── //

class _CustomerPicker extends StatelessWidget {
  const _CustomerPicker({
    required this.controller,
    required this.selected,
    required this.suggestions,
    required this.onQueryChanged,
    required this.onSelect,
    required this.onClear,
    required this.label,
  });

  final TextEditingController controller;
  final AppUser? selected;
  final List<AppUser> suggestions;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<AppUser> onSelect;
  final VoidCallback onClear;
  final String Function(AppUser) label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          readOnly: selected != null,
          onChanged: onQueryChanged,
          decoration: InputDecoration(
            hintText: 'Search by name, phone or email…',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: selected != null
                ? IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: onClear,
                  )
                : null,
          ),
        ),
        if (suggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.divider),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: suggestions.take(6).map((u) {
                return InkWell(
                  onTap: () => onSelect(u),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    child: Row(
                      children: [
                        _Avatar(name: u.fullName),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                u.fullName.isNotEmpty
                                    ? u.fullName
                                    : '(No name)',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14),
                              ),
                              if (u.phone.isNotEmpty)
                                Text(u.phone,
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              if (u.email.isNotEmpty)
                                Text(u.email,
                                    style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 11),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right,
                            color: AppColors.textMuted, size: 18),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}

class _SelectedCard extends StatelessWidget {
  const _SelectedCard({required this.user, required this.onClear});
  final AppUser user;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: AppColors.success.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline,
              color: AppColors.success, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName.isNotEmpty ? user.fullName : '(No name)',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 14),
                ),
                if (user.phone.isNotEmpty)
                  Text(user.phone,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          TextButton(
            onPressed: onClear,
            child: const Text('Change',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final letter =
        name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          letter,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

class _QuickMessageRow extends StatelessWidget {
  const _QuickMessageRow({required this.onTap});
  final void Function(String title, String body) onTap;

  static const _templates = [
    (
      'Your order is ready',
      'Your order is being prepared and will be delivered soon. Thank you for shopping with Abeni Mart!'
    ),
    (
      'Out for delivery',
      'Great news! Your order is out for delivery. Please keep your phone nearby.'
    ),
    (
      'Payment reminder',
      'We haven\'t received your bank transfer yet. Please send your payment so we can process your order.'
    ),
    (
      'Thank you!',
      'Thank you for your order! We hope you enjoy your purchase. Please rate us 5 stars 😊'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Quick templates',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: _templates
              .map((t) => ActionChip(
                    label: Text(t.$1, style: const TextStyle(fontSize: 12)),
                    onPressed: () => onTap(t.$1, t.$2),
                    backgroundColor:
                        AppColors.primary.withOpacity(0.07),
                    side: BorderSide(
                        color: AppColors.primary.withOpacity(0.2)),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withOpacity(0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800),
    );
  }
}

class _SendBar extends StatelessWidget {
  const _SendBar({required this.sending, required this.onSend});
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SizedBox(
        height: 50,
        child: ElevatedButton.icon(
          onPressed: sending ? null : onSend,
          icon: sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.send_rounded),
          label: Text(sending ? 'Sending…' : 'Send message'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 60,
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ],
    );
  }
}
