import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/utils/snackbar_utils.dart';
import '../providers/devices_provider.dart';
import '../widgets/states.dart';

class DevicesPage extends ConsumerStatefulWidget {
  const DevicesPage({super.key});

  @override
  ConsumerState<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends ConsumerState<DevicesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(devicesProvider.notifier).load(),
    );
  }

  Future<void> _confirmDelete(BuildContext ctx, int id, bool isCurrent,
      String name) async {
    final confirmed = await showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Удалить устройство?'),
        content: Text(isCurrent
            ? 'Это текущее устройство. После удаления вы будете выйдете из системы.'
            : 'Удалить устройство "$name"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Отмена')),
          TextButton(
              onPressed: () => Navigator.pop(c, true),
              child: Text(isCurrent ? 'Выйти и удалить' : 'Удалить',
                  style: const TextStyle(color: Color(0xFFE74C3C)))),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(devicesProvider.notifier).delete(id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(devicesProvider);

    // Show error SnackBar when devices are already loaded but a delete fails etc.
    ref.listen<DevicesState>(devicesProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error && next.devices.isNotEmpty) {
        showErrorSnack(context, next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои устройства'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading
                ? null
                : ref.read(devicesProvider.notifier).load,
          ),
        ],
      ),
      body: _buildBody(context, state),
    );
  }

  Widget _buildBody(BuildContext context, DevicesState state) {
    if (state.isLoading && state.devices.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null && state.devices.isEmpty) {
      return ErrorDisplay(
        message: state.error!,
        onRetry: ref.read(devicesProvider.notifier).load,
      );
    }
    if (state.devices.isEmpty) {
      return const Center(child: Text('Нет устройств'));
    }

    return RefreshIndicator(
      onRefresh: ref.read(devicesProvider.notifier).load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: state.devices.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (ctx, i) {
          final d = state.devices[i];
          final lastUsed = d.lastUsed != null
              ? DateFormat('dd.MM.yyyy HH:mm').format(d.lastUsed!.toLocal())
              : 'Неизвестно';

          return Card(
            child: ListTile(
              leading: Icon(
                d.isCurrent ? Icons.phone_android : Icons.devices_other,
                color: d.isCurrent
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              title: Row(
                children: [
                  Expanded(
                      child: Text(d.deviceName,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold))),
                  if (d.isCurrent)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Текущее',
                        style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer),
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (d.ipAddress != null) Text('IP: ${d.ipAddress}'),
                  Text('Последний вход: $lastUsed'),
                ],
              ),
              isThreeLine: d.ipAddress != null,
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Color(0xFFE74C3C)),
                onPressed: () =>
                    _confirmDelete(context, d.id, d.isCurrent, d.deviceName),
              ),
            ),
          );
        },
      ),
    );
  }
}
