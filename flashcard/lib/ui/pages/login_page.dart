import 'package:flashcard/state_management/cubits/auth_cubit/auth_cubit.dart';
import 'package:flashcard/theme/app_colors.dart';
import 'package:flashcard/theme/app_text_styles.dart';
import 'package:flashcard/theme/dimensions.dart';
import 'package:flashcard/ui/widgets/motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    if (_username.text.trim().isEmpty || _password.text.isEmpty) return;
    context.read<AuthCubit>().login(_username.text, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Dimensions.paddingLarge),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: BlocBuilder<AuthCubit, AuthState>(
                builder: (context, state) {
                  final failure = state is UnauthenticatedAuthState
                      ? state
                      : null;
                  final submitting = failure?.submitting ?? false;
                  return AutofillGroup(
                    child: FadeSlideIn(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: colors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(
                                  Dimensions.radiusLg,
                                ),
                              ),
                              child: Icon(
                                Icons.style_rounded,
                                color: colors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingLarge),
                          Text(
                            'Bentornato',
                            style: AppTextStyles.displayMd.copyWith(
                              color: colors.ink,
                            ),
                          ),
                          const SizedBox(height: Dimensions.paddingSmall),
                          Text(
                            'Accedi per ripassare le tue flashcard.',
                            style: AppTextStyles.bodyMd.copyWith(
                              color: colors.muted,
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceXl),
                          TextField(
                            controller: _username,
                            enabled: !submitting,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Username',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                          ),
                          const SizedBox(height: Dimensions.spaceSm),
                          TextField(
                            controller: _password,
                            enabled: !submitting,
                            obscureText: !_showPassword,
                            autofillHints: const [AutofillHints.password],
                            textInputAction: TextInputAction.go,
                            onSubmitted: (_) => _submit(),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                              ),
                              suffixIcon: IconButton(
                                tooltip: _showPassword
                                    ? 'Nascondi password'
                                    : 'Mostra password',
                                icon: Icon(
                                  _showPassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () => setState(
                                  () => _showPassword = !_showPassword,
                                ),
                              ),
                            ),
                          ),
                          if (failure?.message != null) ...[
                            const SizedBox(height: Dimensions.spaceSm),
                            Text(
                              failure!.message!,
                              style: AppTextStyles.bodySm.copyWith(
                                color: colors.didntKnow,
                              ),
                            ),
                          ],
                          const SizedBox(height: Dimensions.paddingLarge),
                          FilledButton(
                            onPressed: submitting ? null : _submit,
                            child: submitting
                                ? const SizedBox.square(
                                    dimension: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Accedi'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
