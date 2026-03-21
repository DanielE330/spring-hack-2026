import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/utils/screen_protection.dart';
import '../providers/qr_provider.dart';

class QrPage extends ConsumerStatefulWidget {
  const QrPage({super.key});

  @override
  ConsumerState<QrPage> createState() => _QrPageState();
}

class _QrPageState extends ConsumerState<QrPage> {
  @override
  void initState() {
    super.initState();
    enableScreenProtection();

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(qrProvider.notifier).generate(),
    );
  }

  @override
  void dispose() {
    disableScreenProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final qr = ref.watch(qrProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ваш QR-пропуск'),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (qr.isLoading)
                  const SizedBox(
                    height: 260,
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (qr.error != null)
                  _ErrorView(
                    error: qr.error!,
                    onRetry: ref.read(qrProvider.notifier).generate,
                  )
                else if (qr.qrToken != null) ...[
                  // QR code card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20)),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: QrImageView(
                        data: qr.qrToken!.token,
                        version: QrVersions.auto,
                        size: 240,
                        backgroundColor: Colors.white,
                        errorStateBuilder: (ctx, err) => const Icon(
                          Icons.error,
                          size: 100,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Countdown
                  _CountdownWidget(secondsLeft: qr.secondsLeft),
                  const SizedBox(height: 8),
                  Text(
                    'QR обновится автоматически',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: qr.isLoading
                        ? null
                        : () => ref.read(qrProvider.notifier).generate(forceNew: true),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Обновить QR'),
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

class _CountdownWidget extends StatelessWidget {
  const _CountdownWidget({required this.secondsLeft});

  final int secondsLeft;

  Color _color(BuildContext ctx) {
    if (secondsLeft > 30) return Colors.green;
    if (secondsLeft > 10) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, color: color, size: 20),
        const SizedBox(width: 6),
        Text(
          '$secondsLeft сек',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image_outlined, size: 64, color: Color(0xFFE74C3C)),
          const SizedBox(height: 12),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: onRetry, child: const Text('Повторить')),
        ],
      ),
    );
  }
}
