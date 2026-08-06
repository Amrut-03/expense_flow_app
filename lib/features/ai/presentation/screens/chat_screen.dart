import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/app_colors.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/theme/theme_cubit.dart';
import 'package:expense_flow_app/core/widgets/neu_app_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_snack_bar.dart';
import 'package:expense_flow_app/core/widgets/neu_text_field.dart';
import 'package:expense_flow_app/core/widgets/tab_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../bloc/chat_bloc.dart';
import '../bloc/chat_event.dart';
import '../bloc/chat_state.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  bool _isStreaming(ChatState state) {
    return state is ChatLoading ||
        (state is ChatAnswer && state.tokens.isNotEmpty);
  }

  void _send([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;
    final state = context.read<ChatBloc>().state;
    if (_isStreaming(state)) return;
    _controller.clear();
    context.read<ChatBloc>().add(SendQuestion(text));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: TabReveal(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: NeuAppBar(
                  title: 'AI Assistant',
                  trailing: _InfoButton(
                    onTap: () => _showInstructions(context, palette),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              Expanded(
                child: BlocBuilder<ChatBloc, ChatState>(
                  builder: (context, state) {
                    _scrollToBottom();
                    final items = _buildItems(state);
                    if (items.isEmpty) {
                      return _emptyState(palette);
                    }
                    return ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.w,
                        vertical: 8.h,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final isLast = index == items.length - 1;
                        return _MessageBubble(
                              message: items[index],
                              palette: palette,
                            )
                            .animate(
                              // Newest message (user ask or assistant reply) pops in
                              // gently; earlier history just fades on initial mount.
                              delay: isLast
                                  ? const Duration(milliseconds: 80)
                                  : Duration.zero,
                            )
                            .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                            .slideY(
                              begin: 0.08,
                              end: 0,
                              curve: Curves.easeOutCubic,
                            );
                      },
                    );
                  },
                ),
              ),
              _inputBar(palette),
            ],
          ),
        ),
      ),
    );
  }

  List<_Message> _buildItems(ChatState state) {
    final items = <_Message>[
      for (final m in state.messages) _Message(text: m.text, isUser: m.isUser),
    ];

    if (state is ChatLoading) {
      items.add(_Message.typing());
    } else if (state is ChatAnswer && state.tokens.isNotEmpty) {
      items.add(
        _Message(
          text: ChatBloc.cleanAnswer(state.tokens.join()),
          isUser: false,
        ),
      );
    } else if (state is ChatError) {
      // The failed assistant message (the friendly error) is already part of
      // the conversation; flag the last one so it renders with retry affordance.
      final lastIsError =
          state.messages.isNotEmpty &&
          state.messages.last.text == state.message &&
          !state.messages.last.isUser;
      if (lastIsError && items.isNotEmpty) {
        items[items.length - 1] = _Message(
          text: state.message,
          isUser: false,
          isError: true,
        );
      }
    }

    return items;
  }

  Widget _emptyState(NeuPalette palette) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🤖', style: TextStyle(fontSize: 64.sp))
                .animate()
                .fadeIn(duration: 320.ms, curve: Curves.easeOut)
                .scale(
                  begin: const Offset(0.7, 0.7),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            SizedBox(height: 16.h),
            Text(
                  'Ask me anything about\nyour expenses',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.manrope(
                    fontSize: 14.sp,
                    height: 1.5,
                    color: palette.textMuted,
                  ),
                )
                .animate(delay: 120.ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
            SizedBox(height: 24.h),
            Wrap(
              spacing: 10.w,
              runSpacing: 10.h,
              alignment: WrapAlignment.center,
              children: [
                for (final suggestion in _suggestions)
                  _SuggestionChip(
                        label: suggestion,
                        onTap: () => _send(suggestion),
                      )
                      .animate(
                        delay: (200 + _suggestions.indexOf(suggestion) * 50).ms,
                      )
                      .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                      .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static const List<String> _suggestions = [
    'How much did I spend this month?',
    'What is my biggest expense?',
    'How is my budget doing?',
  ];

  Widget _inputBar(NeuPalette palette) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child:
                NeuTextField(
                      controller: _controller,
                      hint: 'Ask about your expenses...',
                      maxLines: 1,
                      height: 48,
                      radius: 24,
                      textInputAction: TextInputAction.send,
                      onFieldSubmitted: (_) => _send(),
                    )
                    .animate()
                    .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                    .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic),
          ),
          SizedBox(width: 10.w),
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final sending =
                  state is ChatLoading ||
                  (state is ChatAnswer && state.tokens.isNotEmpty);
              return GestureDetector(
                    onTap: sending ? null : _send,
                    child: Container(
                      width: 48.w,
                      height: 48.w,
                      alignment: Alignment.center,
                      decoration: NeuBox.raised(
                        palette,
                        radius: 24.r,
                        bgColor: palette.accent,
                      ),
                      child: sending
                          ? SizedBox(
                              width: 20.sp,
                              height: 20.sp,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: palette.onAccent,
                              ),
                            )
                          : Icon(
                              Icons.send_rounded,
                              size: 22.sp,
                              color: palette.onAccent,
                            ),
                    ),
                  )
                  .animate(delay: 80.ms)
                  .fadeIn(duration: 280.ms, curve: Curves.easeOut)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            },
          ),
        ],
      ),
    );
  }

  void _showInstructions(BuildContext context, NeuPalette palette) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _InstructionsSheet(palette: palette),
    );
  }
}

class _InfoButton extends StatelessWidget {
  const _InfoButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 44.w,
        height: 44.h,
        alignment: Alignment.center,
        decoration: NeuBox.raised(palette, radius: 16.r),
        child: Icon(
          Icons.info_outline_rounded,
          size: 22.sp,
          color: palette.textDark,
        ),
      ),
    );
  }
}

class _InstructionsSheet extends StatelessWidget {
  const _InstructionsSheet({required this.palette});

  final NeuPalette palette;

  static const List<({String icon, String title, String body})> _items = [
    (
      icon: '📝',
      title: 'Ask naturally',
      body:
          'Type a question like "How much did I spend on food last month?" '
          'instead of using keywords.',
    ),
    (
      icon: '📊',
      title: 'Expense-aware',
      body:
          'The assistant answers from your expenses, budgets, and categories. '
          'It only knows what is stored in this app.',
    ),
    (
      icon: '💬',
      title: 'Follow-ups',
      body:
          'Ask follow-ups like "what about this month?" — it remembers the '
          'recent conversation.',
    ),
    (
      icon: '🔒',
      title: 'Not financial advice',
      body:
          'Answers are informational only and should not replace a '
          'professional\'s advice.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 24.w, 24.w, 32.h),
      decoration: BoxDecoration(
        color: palette.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44.w,
                height: 5.h,
                decoration: BoxDecoration(
                  color: palette.shadowDark.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              'How to use the AI assistant',
              style: AppTextStyles.manrope(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: palette.textDark,
              ),
            ),
            SizedBox(height: 16.h),
            for (final item in _items)
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      alignment: Alignment.center,
                      decoration: NeuBox.raised(palette, radius: 13.r),
                      child: Text(item.icon, style: TextStyle(fontSize: 18.sp)),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.manrope(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: palette.textDark,
                            ),
                          ),
                          SizedBox(height: 3.h),
                          Text(
                            item.body,
                            style: AppTextStyles.manrope(
                              fontSize: 12.sp,
                              height: 1.45,
                              color: palette.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  const _SuggestionChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Text(
          label,
          style: AppTextStyles.manrope(
            fontSize: 12.sp,
            color: palette.textDark,
          ),
        ),
      ),
    );
  }
}

class _Message {
  final String text;
  final bool isUser;
  final bool isTyping;
  final bool isError;

  const _Message({
    required this.text,
    required this.isUser,
    this.isTyping = false,
    this.isError = false,
  });

  factory _Message.typing() =>
      const _Message(text: '', isUser: false, isTyping: true);
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, required this.palette});

  final _Message message;
  final NeuPalette palette;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final isError = message.isError;
    final bubbleColor = isUser
        ? palette.accent
        : isError
        ? palette.danger.withValues(alpha: 0.12)
        : palette.background;
    final textColor = isUser
        ? palette.onAccent
        : isError
        ? palette.danger
        : palette.textDark;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 4.h),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            decoration: NeuBox.raised(
              palette,
              radius: 16.r,
            ).copyWith(color: bubbleColor),
            child: message.isTyping
                ? _TypingIndicator(color: palette.textMuted)
                : Text(
                    message.text,
                    textAlign: isUser ? TextAlign.right : TextAlign.left,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      height: 1.5,
                      color: textColor,
                    ),
                  ),
          ),
          if (isError)
            GestureDetector(
              onTap: () => _retry(context),
              child: Padding(
                padding: EdgeInsets.only(left: 8.w, top: 2.h, bottom: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.refresh_rounded,
                      size: 14.sp,
                      color: palette.accent,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Try again',
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w600,
                        color: palette.accent,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else if (!isUser && !message.isTyping)
            GestureDetector(
              onTap: () => _copy(context),
              child: Padding(
                padding: EdgeInsets.only(left: 8.w, bottom: 4.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.copy_rounded,
                      size: 14.sp,
                      color: palette.textMuted,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      'Copy',
                      style: AppTextStyles.manrope(
                        fontSize: 11.sp,
                        color: palette.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    NeuSnackBar.show(
      context: context,
      message: 'Answer copied to clipboard',
      type: NeuSnackBarType.success,
    );
  }

  void _retry(BuildContext context) {
    context.read<ChatBloc>().add(const RetryQuestion());
  }
}

class _TypingIndicator extends StatefulWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  State<_TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<_TypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 3; i++)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.25, end: 1).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Interval(
                      i * 0.2,
                      0.6 + i * 0.2,
                      curve: Curves.easeInOut,
                    ),
                  ),
                ),
                child: Container(
                  width: 6.sp,
                  height: 6.sp,
                  decoration: BoxDecoration(
                    color: widget.color,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
