import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_input.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/error_helpers.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/sources/auth_remote_data_source.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final dataSource = AuthRemoteDataSource();
      await dataSource.requestPasswordReset(email: _emailCtrl.text.trim());

      if (mounted) {
        setState(() {
          _successMessage = 'Ссылка для восстановления отправлена на вашу почту';
          _isLoading = false;
        });

        // Через 3 секунды вернёмся на страницу входа
        await Future.delayed(const Duration(seconds: 3));
        if (mounted) {
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = extractErrorMessage(e);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Восстановление пароля'),
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
                const SizedBox(height: 32),
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Icon(Icons.lock_reset_rounded, size: 44, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Восстановление пароля',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Введите email, связанный с вашим аккаунтом.\nМы отправим ссылку для восстановления пароля.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                AppInput(
                  controller: _emailCtrl,
                  label: 'Email',
                  hint: 'example@mail.com',
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.done,
                  validator: Validators.email,
                  autofillHints: const [AutofillHints.email],
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 24),
                if (_successMessage != null) ...[
                  InlineMessageBanner.success(_successMessage!),
                  const SizedBox(height: 24),
                ],
                if (_errorMessage != null) ...[
                  InlineMessageBanner.error(_errorMessage!),
                  const SizedBox(height: 24),
                ],
                AppButton(
                  label: 'Отправить ссылку',
                  onPressed: _submit,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: _isLoading ? null : () => context.pop(),
                    child: const Text('Вернуться на вход'),
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
