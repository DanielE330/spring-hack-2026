import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/validators.dart';
import '../../core/utils/snackbar_utils.dart';
import '../providers/create_user_provider.dart';
import '../widgets/app_button.dart';
import '../widgets/app_input.dart';

class CreateUserPage extends ConsumerStatefulWidget {
  const CreateUserPage({super.key});

  @override
  ConsumerState<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends ConsumerState<CreateUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _surnameCtrl = TextEditingController();
  final _patronymicCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isAdmin = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _nameCtrl.dispose();
    _surnameCtrl.dispose();
    _patronymicCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final ok = await ref.read(createUserProvider.notifier).createUser(
          email: _emailCtrl.text.trim(),
          name: _nameCtrl.text.trim(),
          surname: _surnameCtrl.text.trim(),
          patronymic: _patronymicCtrl.text.trim().isEmpty
              ? null
              : _patronymicCtrl.text.trim(),
          password: _passCtrl.text,
          isAdmin: _isAdmin,
        );

    if (!mounted) return;

    if (ok) {
      if (!mounted) return;
      showSuccessSnack(context, 'Пользователь успешно создан');
      _formKey.currentState?.reset();
      _emailCtrl.clear();
      _nameCtrl.clear();
      _surnameCtrl.clear();
      _patronymicCtrl.clear();
      _passCtrl.clear();
      setState(() => _isAdmin = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createUserProvider);
    final theme = Theme.of(context);

    ref.listen<CreateUserState>(createUserProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnack(context, next.error!);
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Новый пользователь'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withAlpha(25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.person_add_rounded,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                  'Создание аккаунта',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Заполните данные нового пользователя',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Surname
                AppInput(
                  controller: _surnameCtrl,
                  label: 'Фамилия *',
                  hint: 'Иванов',
                  textInputAction: TextInputAction.next,
                  validator: (v) => Validators.required(v, 'Фамилия'),
                  autofillHints: const [AutofillHints.familyName],
                ),
                const SizedBox(height: 16),

                // Name
                AppInput(
                  controller: _nameCtrl,
                  label: 'Имя *',
                  hint: 'Иван',
                  textInputAction: TextInputAction.next,
                  validator: Validators.name,
                  autofillHints: const [AutofillHints.givenName],
                ),
                const SizedBox(height: 16),

                // Patronymic
                AppInput(
                  controller: _patronymicCtrl,
                  label: 'Отчество',
                  hint: 'Иванович',
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.middleName],
                ),
                const SizedBox(height: 16),

                // Email
                AppInput(
                  controller: _emailCtrl,
                  label: 'Email *',
                  hint: 'user@example.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: Validators.email,
                  autofillHints: const [AutofillHints.email],
                ),
                const SizedBox(height: 16),

                // Password
                AppInput(
                  controller: _passCtrl,
                  label: 'Пароль *',
                  hint: 'Минимум 8 символов',
                  obscureText: _obscurePass,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Введите пароль';
                    if (v.length < 8) return 'Минимум 8 символов';
                    return null;
                  },
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePass
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                const SizedBox(height: 20),

                // Admin switch
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: _isAdmin
                        ? theme.colorScheme.primary.withAlpha(25)
                        : theme.colorScheme.surfaceContainerHighest
                            .withAlpha(80),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isAdmin
                          ? theme.colorScheme.primary.withAlpha(80)
                          : theme.colorScheme.outline.withAlpha(40),
                    ),
                  ),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Администратор'),
                    subtitle: Text(
                      _isAdmin
                          ? 'Будут полные права'
                          : 'Обычный пользователь',
                      style: theme.textTheme.bodySmall,
                    ),
                    secondary: Icon(
                      _isAdmin
                          ? Icons.admin_panel_settings_rounded
                          : Icons.person_rounded,
                      color: _isAdmin
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    value: _isAdmin,
                    onChanged: (v) => setState(() => _isAdmin = v),
                  ),
                ),
                const SizedBox(height: 32),

                // Submit
                AppButton(
                  label: 'Создать пользователя',
                  isLoading: state.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
