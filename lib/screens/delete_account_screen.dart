import 'package:flutter/material.dart';
import 'package:smartcart/database/database_helper.dart';
import 'package:smartcart/models/models.dart';

class DeleteAccountScreen extends StatefulWidget {
  final UserModel user;

  const DeleteAccountScreen({
    super.key,
    required this.user,
  });

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool _isDeleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _confirmAndDelete() async {
    if (!_formKey.currentState!.validate()) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Остаточне видалення'),
        content: const Text(
          'Ви впевнені, що хочете видалити акаунт? Цю дію неможливо скасувати.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Скасувати'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('Видалити назавжди'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);

    try {
      final success = await DatabaseHelper.instance.deleteAccount(
        userId: widget.user.id!,
        password: _passwordController.text,
      );

      if (!mounted) return;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Невірний пароль. Видалення скасовано.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Обліковий запис та всі дані успішно видалено'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (route) => false,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Помилка під час видалення: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Видалення акаунту'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.warning_amber_rounded,
                            color: colorScheme.onErrorContainer,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Увага! Незворотна дія',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Після підтвердження пароля ваш профіль (${widget.user.email}), активна сесія, усі списки покупок та історія змін цін будуть безповоротно видалені з бази даних.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: colorScheme.onErrorContainer,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Підтвердьте свою особу',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Введіть поточний пароль від акаунту «${widget.user.name}»:',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _confirmAndDelete(),
                      decoration: InputDecoration(
                        labelText: 'Поточний пароль',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Введіть пароль для підтвердження';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      onPressed: _isDeleting ? null : _confirmAndDelete,
                      style: FilledButton.styleFrom(
                        backgroundColor: colorScheme.error,
                        foregroundColor: colorScheme.onError,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      icon: _isDeleting
                          ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                          : const Icon(Icons.delete_forever_rounded),
                      label: const Text(
                        'Видалити акаунт',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      onPressed:
                      _isDeleting ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text('Повернутися назад'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}