import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/neumorphic_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();

    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        SignInRequested(
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
            }

            if (state is AuthError) {
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
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 40),

                            Text(
                                  l10n.auth_welcomeBack,
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
                                  l10n.auth_loginSubtitle,
                                  style: AppTextStyles.manrope(
                                    fontSize: 12,
                                    color: palette.textMuted,
                                  ),
                                )
                                .animate(delay: 80.ms)
                                .fadeIn(
                                  duration: 300.ms,
                                  curve: Curves.easeOut,
                                ),

                            const SizedBox(height: 32),

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
                                .animate(delay: 140.ms)
                                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.06,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),

                            SizedBox(height: 14.h),

                            NeuTextField(
                                  controller: _passwordController,
                                  hint: l10n.auth_password,
                                  obscureText: _obscurePassword,
                                  textInputAction: TextInputAction.done,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => _submit(),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off
                                          : Icons.visibility,
                                      size: 18.h,
                                      color: palette.textMuted,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscurePassword = !_obscurePassword;
                                      });
                                    },
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return l10n.auth_passwordRequired;
                                    }

                                    if (value.length < 6) {
                                      return l10n.auth_passwordMinChars;
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

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  context.push('/forgot-password');
                                },
                                child: Text(
                                  l10n.auth_forgotPassword,
                                  style: AppTextStyles.manrope(
                                    fontSize: 11,
                                    color: palette.accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ).animate(delay: 440.ms)
                                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                                .slideY(
                              begin: 0.06,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            ),

                            const SizedBox(height: 8),

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
                                            l10n.auth_logIn,
                                            style: AppTextStyles.manrope(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w700,
                                              color: palette.onAccent,
                                            ),
                                          ),
                                  ),
                                )
                                .animate(delay: 280.ms)
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
                                .animate(delay: 360.ms)
                                .fadeIn(
                                  duration: 300.ms,
                                  curve: Curves.easeOut,
                                ),

                            const SizedBox(height: 16),

                            NeuButton(
                              label: l10n.common_google,
                              onTap: isLoading
                                  ? null
                                  : () {
                                      context.read<AuthBloc>().add(
                                        const GoogleSignInRequested(),
                                      );
                                    },
                            ).animate(delay: 440.ms)
                                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                                .slideY(
                                  begin: 0.06,
                                  end: 0,
                                  curve: Curves.easeOutCubic,
                                ),

                            // Row(
                            //       children: [
                            //         Expanded(
                            //           child: NeuButton(
                            //             label: l10n.common_google,
                            //             onTap: isLoading
                            //                 ? null
                            //                 : () {
                            //                     context.read<AuthBloc>().add(
                            //                       const GoogleSignInRequested(),
                            //                     );
                            //                   },
                            //           ),
                            //         ),
                            //         const SizedBox(width: 10),
                            //         Expanded(
                            //           child: NeuButton(
                            //             label: l10n.common_apple,
                            //             onTap: isLoading ? null : () {},
                            //           ),
                            //         ),
                            //       ],
                            //     )
                            //     .animate(delay: 440.ms)
                            //     .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                            //     .slideY(
                            //       begin: 0.06,
                            //       end: 0,
                            //       curve: Curves.easeOutCubic,
                            //     ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                        child: GestureDetector(
                          onTap: () => context.push('/signup'),
                          child: RichText(
                            text: TextSpan(
                              style: AppTextStyles.manrope(
                                fontSize: 11,
                                color: palette.textMuted,
                              ),
                              children: [
                                TextSpan(text: l10n.auth_dontHaveAccount),
                                TextSpan(
                                  text: l10n.auth_signUp,
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
                      .animate(delay: 520.ms)
                      .fadeIn(duration: 300.ms, curve: Curves.easeOut),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
