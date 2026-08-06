import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_flow_app/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_flow_app/core/widgets/neu_loading.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      context.read<AuthBloc>().add(ForgotPasswordRequested(email: email));
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return Scaffold(
      backgroundColor: palette.background,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthError) {
            NeuSnackBar.show(
              context: context,
              message: state.message,
              type: NeuSnackBarType.error,
            );
          } else if (state is AuthInitial) {
            NeuSnackBar.show(
              context: context,
              message: AppLocalizations.of(context).auth_passwordResetSent,
              type: NeuSnackBarType.success,
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is AuthLoading;
          final l10n = AppLocalizations.of(context);

          if (state is AuthLoading) {
            return const NeuLoading();
          }

          return SafeArea(
            child: GestureDetector(
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

                      const SizedBox(height: 50),
                      Text(
                            l10n.auth_forgotPasswordTitle,
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
                            l10n.auth_forgotPasswordSubtitle,
                            style: AppTextStyles.manrope(
                              fontSize: 12,
                              color: palette.textMuted,
                            ),
                          )
                          .animate(delay: 80.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut),
                      const SizedBox(height: 50),
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
                                      l10n.auth_sendResetLink,
                                      style: AppTextStyles.manrope(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: palette.onAccent,
                                      ),
                                    ),
                            ),
                          )
                          .animate(delay: 220.ms)
                          .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            curve: Curves.easeOutCubic,
                          ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
