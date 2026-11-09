import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../l10n/app_localizations.dart';
import '../cubit/spending_events_cubit.dart';
import '../screens/events_screen.dart';

/// Dashboard section listing events/trips running today. Empty otherwise.
class ActiveEventsSection extends StatelessWidget {
  const ActiveEventsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);
    final active = context.select<SpendingEventsCubit, List>(
      (c) => c.state.active,
    );
    if (active.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: EdgeInsets.only(top: 24.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.events_dashboardTitle,
            style: AppTextStyles.manrope(
              fontSize: 14.sp,
              color: palette.textDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12.h),
          for (final progress
              in context.read<SpendingEventsCubit>().state.active)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: EventCard(
                progress: progress,
                onTap: () => context.push('/events'),
              ),
            ),
        ],
      ),
    );
  }
}
