import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/guest_pass.dart';
import '../providers/guest_pass_provider.dart';
import '../../core/utils/snackbar_utils.dart';

class GuestPassesPage extends ConsumerStatefulWidget {
  const GuestPassesPage({super.key});

  @override
  ConsumerState<GuestPassesPage> createState() => _GuestPassesPageState();
}

class _GuestPassesPageState extends ConsumerState<GuestPassesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(guestPassProvider.notifier).loadPasses());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(guestPassProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Временные пропуска'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/guest-passes/create'),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Новый пропуск'),
      ),
      body: SafeArea(
        child: state.isLoading && state.passes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : state.passes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.badge_outlined, size: 64, color: theme.colorScheme.outline),
                        const SizedBox(height: 16),
                        Text('Нет гостевых пропусков', style: theme.textTheme.bodyLarge),
                        const SizedBox(height: 8),
                        Text('Создайте первый пропуск',
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.outline)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: () => ref.read(guestPassProvider.notifier).loadPasses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: state.passes.length,
                      itemBuilder: (context, index) =>
                          _GuestPassCard(pass: state.passes[index]),
                    ),
                  ),
      ),
    );
  }
}

class _GuestPassCard extends ConsumerWidget {
  const _GuestPassCard({required this.pass});

  final GuestPass pass;

  Color _statusColor(BuildContext context) {
    switch (pass.status) {
      case 'active':  return Colors.green;
      case 'used':    return Colors.blue;
      case 'expired': return Colors.orange;
      case 'revoked': return Colors.red;
      default:        return Theme.of(context).colorScheme.outline;
    }
  }

  IconData _statusIcon() {
    switch (pass.status) {
      case 'active':  return Icons.check_circle_outline;
      case 'used':    return Icons.done_all_rounded;
      case 'expired': return Icons.timer_off_rounded;
      case 'revoked': return Icons.cancel_outlined;
      default:        return Icons.info_outline;
    }
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final color = _statusColor(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: name + status
            Row(
              children: [
                Expanded(
                  child: Text(
                    pass.guestName,
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withAlpha(isDark ? 40 : 25),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withAlpha(isDark ? 80 : 60)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon(), size: 14, color: color),
                      const SizedBox(width: 4),
                      Text(
                        pass.statusLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Info rows
            if (pass.guestCompany.isNotEmpty)
              _infoRow(Icons.business_rounded, pass.guestCompany, theme),
            _infoRow(Icons.category_rounded, pass.purposeLabel, theme),
            _infoRow(Icons.schedule_rounded,
                '${_formatDate(pass.validFrom)} — ${_formatDate(pass.validUntil)}', theme),
            if (pass.note.isNotEmpty)
              _infoRow(Icons.note_rounded, pass.note, theme),
            if (pass.createdByEmail != null)
              _infoRow(Icons.person_outline, 'Создал: ${pass.createdByEmail}', theme),

            // Action: revoke
            if (pass.status == 'active') ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Отменить пропуск?'),
                        content: Text('Пропуск для «${pass.guestName}» будет отменён.'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Нет')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Да, отменить')),
                        ],
                      ),
                    );
                    if (confirmed == true && context.mounted) {
                      final ok = await ref.read(guestPassProvider.notifier).revokePass(pass.id);
                      if (context.mounted) {
                        if (ok) {
                          showSuccessSnack(context, 'Пропуск отменён');
                        } else {
                          showErrorSnack(context, ref.read(guestPassProvider).error ?? 'Ошибка');
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.cancel_outlined, size: 18),
                  label: const Text('Отменить пропуск'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
