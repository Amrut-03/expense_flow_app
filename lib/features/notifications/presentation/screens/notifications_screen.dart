import 'package:expense_flow_app/core/theme/app_colors.dart';
import 'package:expense_flow_app/core/theme/app_text_styles.dart';
import 'package:expense_flow_app/core/theme/neumorphic_styles.dart';
import 'package:expense_flow_app/core/theme/theme_cubit.dart';
import 'package:expense_flow_app/core/widgets/empty_state.dart';
import 'package:expense_flow_app/core/widgets/neu_app_bar.dart';
import 'package:expense_flow_app/features/notifications/domain/entities/app_notification.dart';
import 'package:expense_flow_app/features/notifications/presentation/bloc/notifications_cubit.dart';
import 'package:expense_flow_app/features/notifications/presentation/bloc/notifications_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the inbox marks everything as read, which clears the unread
    // dot from the bell in the top-right and the bottom navigation bar.
    context.read<NotificationsCubit>().markAllAsRead();
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final state = context.watch<NotificationsCubit>().state;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 4.h),
              child: NeuAppBar(
                title: 'Notifications',
                onBack: () =>
                    context.canPop() ? context.pop() : context.go('/dashboard'),
                trailing: state is NotificationsLoaded && state.hasUnread
                    ? _MarkAllReadButton(palette: palette)
                    : null,
              ),
            ),
            Expanded(child: _buildContent(context, state, palette)),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    NotificationsState state,
    NeuPalette palette,
  ) {
    if (state is NotificationsLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final notifications = state is NotificationsLoaded
        ? state.notifications
        : <AppNotification>[];

    if (notifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Text('🔔', style: TextStyle(fontSize: 40)),
        title: 'All caught up',
        subtitle: 'You have no new notifications.',
        boxed: true,
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
      itemCount: notifications.length,
      itemBuilder: (context, index) =>
          _NotificationTile(
                notification: notifications[index],
                palette: palette,
              )
              .animate(delay: (index * 40).ms)
              .fadeIn(duration: 260.ms, curve: Curves.easeOut)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
    );
  }
}

class _MarkAllReadButton extends StatelessWidget {
  final NeuPalette palette;

  const _MarkAllReadButton({required this.palette});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.read<NotificationsCubit>().clearAll(),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Text(
          'Clear all',
          style: AppTextStyles.manrope(
            fontSize: 12.sp,
            fontWeight: FontWeight.w600,
            color: palette.accent,
          ),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotification notification;
  final NeuPalette palette;

  const _NotificationTile({required this.notification, required this.palette});

  void _open(BuildContext context) {
    context.read<NotificationsCubit>().markNotificationRead(notification.id);
    context.go(notification.type.defaultRoute);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _open(context),
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(14.w),
        decoration: NeuBox.raised(palette, radius: 20.r),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              alignment: Alignment.center,
              decoration: NeuBox.raised(palette, radius: 14.r),
              child: Text(
                notification.emoji,
                style: TextStyle(fontSize: 20.sp),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: AppTextStyles.manrope(
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                            color: palette.textDark,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        _relativeTime(notification.receivedAt),
                        style: AppTextStyles.manrope(
                          fontSize: 11.sp,
                          color: palette.textMuted,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    notification.message,
                    style: AppTextStyles.manrope(
                      fontSize: 13.sp,
                      height: 1.35,
                      color: palette.textMuted,
                    ),
                  ),
                  if (!notification.isRead)
                    Padding(
                      padding: EdgeInsets.only(top: 6.h),
                      child: Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: palette.accent,
                          shape: BoxShape.circle,
                        ),
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

  String _relativeTime(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${time.day}/${time.month}/${time.year}';
  }
}
