import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (!mounted) return;

            if (state is Authenticated) {
              context.go('/dashboard');
            } else if (state is AuthError) {
              NeuSnackBar.show(
                context: context,
                message: state.message,
                type: NeuSnackBarType.error,
              );
            }
          },
          builder: (context, state) {
            final isLoading = state is AuthLoading;
            final l10n = AppLocalizations.of(context);
            return GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),

                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: NeuBox.raised(palette, radius: 12),
                          child: Icon(
                            Icons.arrow_back,
                            size: 18,
                            color: palette.textDark,
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Text(
                            l10n.auth_createAccount,
                            style: AppTextStyles.manrope(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: palette.textDark,
                            ),
                          )
                          .animate()
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 4),
                      Text(
                            l10n.auth_signupSubtitle,
                            style: AppTextStyles.manrope(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          )
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 28),

                      NeuTextField(
                            controller: _nameController,
                            hint: l10n.auth_fullName,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.name],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.auth_nameRequired;
                              }
                              return null;
                            },
                          )
                          .animate(delay: 140.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 14),
                      NeuTextField(
                            controller: _emailController,
                            hint: l10n.auth_emailAddress,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return l10n.auth_emailRequired;
                              }
                              final emailRegex = RegExp(
                                r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$',
                              );
                              if (!emailRegex.hasMatch(value.trim())) {
                                return l10n.auth_invalidEmail;
                              }
                              return null;
                            },
                          )
                          .animate(delay: 200.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 14),
                      NeuTextField(
                            controller: _passwordController,
                            hint: l10n.auth_password,
                            obscureText: _obscurePassword,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.newPassword],
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: palette.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword,
                              ),
                            ),
                            validator: (value) {
                              if (value != _passwordController.text) {
                                return l10n.auth_passwordsDoNotMatch;
                              }
                              return null;
                            },
                          )
                          .animate(delay: 260.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 14),
                      NeuTextField(
                            controller: _confirmPasswordController,
                            hint: l10n.auth_confirmPassword,
                            obscureText: _obscureConfirmPassword,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _submit(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirmPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                                size: 18,
                                color: palette.textMuted,
                              ),
                              onPressed: () => setState(
                                () => _obscureConfirmPassword =
                                    !_obscureConfirmPassword,
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return l10n.auth_confirmPasswordRequired;
                              }
                              if (value != _passwordController.text) {
                                return l10n.auth_passwordsDoNotMatch;
                              }
                              return null;
                            },
                          )
                          .animate(delay: 320.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 24),

                      GestureDetector(
                            onTap: isLoading ? null : _submit,
                            child: Container(
                              height: 48,
                              alignment: Alignment.center,
                              decoration: NeuBox.raised(
                                palette,
                                radius: 24,
                              ).copyWith(color: palette.accent),
                              child: isLoading
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: palette.onAccent,
                                      ),
                                    )
                                  : Text(
                                      l10n.auth_createAccount,
                                      style: AppTextStyles.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: palette.onAccent,
                                      ),
                                    ),
                            ),
                          )
                          .animate(delay: 400.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 20),
                      Center(
                            child: Text(
                              l10n.auth_orContinueWith,
                              style: AppTextStyles.manrope(
                                fontSize: 10,
                                color: palette.textMuted,
                              ),
                            ),
                          )
                          .animate(delay: 480.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 16),

                      Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: isLoading
                                      ? null
                                      : () => context.read<AuthBloc>().add(
                                          GoogleSignInRequested(),
                                        ),
                                  child: Container(
                                    height: 44,
                                    alignment: Alignment.center,
                                    decoration: NeuBox.raised(
                                      palette,
                                      radius: 16,
                                    ),
                                    child: Text(
                                      l10n.common_google,
                                      style: AppTextStyles.manrope(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: palette.textDark,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Container(
                                  height: 44,
                                  alignment: Alignment.center,
                                  decoration: NeuBox.raised(
                                    palette,
                                    radius: 16,
                                  ),
                                  child: Text(
                                    l10n.common_apple,
                                    style: AppTextStyles.manrope(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: palette.textDark,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                          .animate(delay: 560.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),

                      const SizedBox(height: 24),
                      Center(
                            child: GestureDetector(
                              onTap: () => context.pop(),
                              child: RichText(
                                text: TextSpan(
                                  style: AppTextStyles.manrope(
                                    fontSize: 11,
                                    color: palette.textMuted,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: l10n.auth_alreadyHaveAccount,
                                    ),
                                    TextSpan(
                                      text: l10n.auth_logIn,
                                      style: AppTextStyles.manrope(
                                        fontWeight: FontWeight.w700,
                                        color: palette.accent,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          )
                          .animate(delay: 640.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
