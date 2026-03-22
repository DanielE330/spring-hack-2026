import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/guest_pass_provider.dart';
import '../../core/utils/snackbar_utils.dart';

class CreateGuestPassPage extends ConsumerStatefulWidget {
  const CreateGuestPassPage({super.key});

  @override
  ConsumerState<CreateGuestPassPage> createState() => _CreateGuestPassPageState();
}

class _CreateGuestPassPageState extends ConsumerState<CreateGuestPassPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String _purpose = 'meeting';
  DateTime? _validFrom;
  DateTime? _validUntil;
  bool _submitting = false;

  static const _purposes = <String, String>{
    'meeting':       'Встреча',
    'contractor':    'Подрядчик',
    'delivery':      'Доставка/Курьер',
    'temp_employee': 'Временный сотрудник',
    'other':         'Другое',
  };

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _validFrom = now;
    _validUntil = now.add(const Duration(hours: 3));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _companyCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isFrom}) async {
    final initial = isFrom ? _validFrom! : _validUntil!;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;

    final result = DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isFrom) {
        _validFrom = result;
        // Автоматически сдвигаем конец если начало стало позже
        if (_validUntil != null && _validUntil!.isBefore(result)) {
          _validUntil = result.add(const Duration(hours: 1));
        }
      } else {
        _validUntil = result;
      }
    });
  }

  String _formatDt(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_validFrom == null || _validUntil == null) {
      showWarningSnack(context, 'Укажите время действия пропуска');
      return;
    }
    if (_validUntil!.isBefore(_validFrom!) || _validUntil == _validFrom) {
      showWarningSnack(context, 'Конец должен быть позже начала');
      return;
    }

    setState(() => _submitting = true);
    final ok = await ref.read(guestPassProvider.notifier).createPass(
      guestName: _nameCtrl.text.trim(),
      purpose: _purpose,
      validFrom: _validFrom!,
      validUntil: _validUntil!,
      guestCompany: _companyCtrl.text.trim(),
      note: _noteCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (ok) {
      showSuccessSnack(context, 'Гостевой пропуск создан');
      context.pop();
    } else {
      showErrorSnack(context, ref.read(guestPassProvider).error ?? 'Ошибка создания');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Новый гостевой пропуск')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ФИО гостя
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'ФИО гостя *',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите ФИО' : null,
                ),
                const SizedBox(height: 16),

                // Компания
                TextFormField(
                  controller: _companyCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Компания / организация',
                    prefixIcon: Icon(Icons.business_outlined),
                  ),
                ),
                const SizedBox(height: 16),

                // Цель визита
                DropdownButtonFormField<String>(
                  value: _purpose,
                  decoration: const InputDecoration(
                    labelText: 'Цель визита *',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _purposes.entries
                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) => setState(() => _purpose = v ?? 'meeting'),
                ),
                const SizedBox(height: 16),

                // Время начала
                _DateTimeTile(
                  label: 'Начало действия',
                  value: _validFrom != null ? _formatDt(_validFrom!) : 'Не выбрано',
                  icon: Icons.play_arrow_rounded,
                  onTap: () => _pickDateTime(isFrom: true),
                ),
                const SizedBox(height: 12),

                // Время конца
                _DateTimeTile(
                  label: 'Конец действия',
                  value: _validUntil != null ? _formatDt(_validUntil!) : 'Не выбрано',
                  icon: Icons.stop_rounded,
                  onTap: () => _pickDateTime(isFrom: false),
                ),
                const SizedBox(height: 8),

                // Быстрые кнопки длительности
                Wrap(
                  spacing: 8,
                  children: [
                    _DurationChip(label: '30 мин', onTap: () => _setDuration(minutes: 30)),
                    _DurationChip(label: '1 час', onTap: () => _setDuration(hours: 1)),
                    _DurationChip(label: '3 часа', onTap: () => _setDuration(hours: 3)),
                    _DurationChip(label: '1 день', onTap: () => _setDuration(days: 1)),
                    _DurationChip(label: '1 неделя', onTap: () => _setDuration(days: 7)),
                  ],
                ),
                const SizedBox(height: 16),

                // Комментарий
                TextFormField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Комментарий',
                    prefixIcon: Icon(Icons.note_outlined),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 32),

                // Кнопка создания
                FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.badge_rounded),
                  label: const Text('Создать пропуск'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _setDuration({int minutes = 0, int hours = 0, int days = 0}) {
    final from = DateTime.now();
    setState(() {
      _validFrom = from;
      _validUntil = from.add(Duration(minutes: minutes, hours: hours, days: days));
    });
  }
}

class _DateTimeTile extends StatelessWidget {
  const _DateTimeTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline.withAlpha(80)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.outline)),
                  const SizedBox(height: 2),
                  Text(value, style: theme.textTheme.bodyLarge),
                ],
              ),
            ),
            Icon(Icons.edit_calendar_rounded, size: 20, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
    );
  }
}
