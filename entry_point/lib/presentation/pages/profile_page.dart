import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  bool _avatarLoading = false;

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1024, imageQuality: 85);
    if (picked == null) return;

    setState(() => _avatarLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.uploadAvatar(picked.path);
      // Refresh user data to get new avatar URL
      await ref.read(authProvider.notifier).init();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватарка обновлена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _avatarLoading = true);
    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.deleteAvatar();
      await ref.read(authProvider.notifier).init();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Аватарка удалена')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarLoading = false);
    }
  }

  void _showAvatarOptions() {
    final user = ref.read(authProvider).user;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Выбрать из галереи'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAndUploadAvatar();
              },
            ),
            if (user?.avatarUrl != null)
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Color(0xFFE74C3C)),
                title: const Text('Удалить аватарку', style: TextStyle(color: Color(0xFFE74C3C))),
                onTap: () {
                  Navigator.pop(ctx);
                  _deleteAvatar();
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Профиль')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              // Avatar
              GestureDetector(
                onTap: _avatarLoading ? null : _showAvatarOptions,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      backgroundImage: user?.avatarUrl != null
                          ? NetworkImage(user!.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null
                          ? Text(
                              user?.initials ?? '?',
                              style: Theme.of(context).textTheme.headlineLarge?.copyWith(color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _avatarLoading
                            ? const SizedBox(
                                width: 16, height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.fullName ?? '—',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              if (auth.isAdmin)
                Chip(
                  avatar: Icon(Icons.admin_panel_settings, size: 18, color: Theme.of(context).colorScheme.primary),
                  label: Text('Администратор', style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
                  backgroundColor:
                      Theme.of(context).colorScheme.secondaryContainer,
                ),
              const Divider(height: 40),

              // Info rows
              _InfoRow(
                label: 'Фамилия',
                value: user?.surname ?? '—',
              ),
              _InfoRow(
                label: 'Имя',
                value: user?.name ?? '—',
              ),
              if (user?.patronymic != null)
                _InfoRow(label: 'Отчество', value: user!.patronymic!),
              _InfoRow(label: 'E-mail', value: user?.email ?? '—'),
              const Spacer(),

              // Logout
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: auth.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(authProvider.notifier)
                              .logout();
                          if (context.mounted) context.go('/login');
                        },
                  icon: auth.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout),
                  label: const Text('Выйти'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant)),
          ),
          Expanded(
            child: Text(value,
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
