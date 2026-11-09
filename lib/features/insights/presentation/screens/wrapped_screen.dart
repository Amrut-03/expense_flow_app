import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/expense_category.dart';
import '../../../../core/constants/payment_methods.dart';
import '../../../../core/logging/app_log_buffer.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_cubit.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/neu_app_bar.dart';
import '../../../../core/widgets/neu_button.dart';
import '../../../../core/widgets/neu_loading.dart';
import '../../../../core/widgets/neu_snack_bar.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../currency/presentation/cubit/currency_cubit.dart';
import '../../domain/services/year_in_review.dart';
import '../cubit/wrapped_cubit.dart';

/// Year-in-review story cards, shareable as images.
class WrappedScreen extends StatefulWidget {
  const WrappedScreen({super.key});

  @override
  State<WrappedScreen> createState() => _WrappedScreenState();
}

class _WrappedScreenState extends State<WrappedScreen> {
  final _pageController = PageController(viewportFraction: .92);
  final _keys = List.generate(5, (_) => GlobalKey());
  int _page = 0;
  bool _sharing = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _share(int year) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _sharing = true);
    try {
      final boundary =
          _keys[_page].currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/expenseflow_wrapped_${year}_$_page.png');
      await file.writeAsBytes(bytes!.buffer.asUint8List(), flush: true);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: l10n.wrapped_shareText(year),
        ),
      );
    } catch (e, st) {
      AppLogBuffer.instance.captureError('wrapped.share', e, st);
      if (mounted) {
        NeuSnackBar.show(
          context: context,
          message: l10n.export_failed,
          type: NeuSnackBarType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.watch<ThemeCubit>().state.palette;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: BlocBuilder<WrappedCubit, WrappedState>(
          builder: (context, state) {
            final cubit = context.read<WrappedCubit>();
            final review = state.review;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 10.h, 24.w, 0),
                  child: NeuAppBar(
                    title: l10n.wrapped_title,
                    onBack: () => context.pop(),
                  ),
                ),
                if (state.loading)
                  const Expanded(child: Center(child: NeuLoading()))
                else if (review == null || review.isEmpty)
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 24.w),
                        child: EmptyStateWidget(
                          icon: Text('🎁', style: TextStyle(fontSize: 40.sp)),
                          title: l10n.wrapped_emptyTitle,
                          subtitle: l10n.wrapped_emptyHint(
                            YearInReview.minTransactions,
                          ),
                        ),
                      ),
                    ),
                  )
                else ...[
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 40.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 24.w),
                      children: [
                        for (final y in state.years)
                          Padding(
                            padding: EdgeInsets.only(right: 8.w),
                            child: ChoiceChip(
                              label: Text('$y'),
                              selected: y == review.year,
                              onSelected: (_) {
                                cubit.selectYear(y);
                                _pageController.jumpToPage(0);
                              },
                            ),
                          ),
                        FilterChip(
                          label: Text(l10n.wrapped_hideAmounts),
                          selected: state.hideAmounts,
                          onSelected: (_) => cubit.toggleHideAmounts(),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (p) => setState(() => _page = p),
                      children: [
                        for (var i = 0; i < _keys.length; i++)
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: RepaintBoundary(
                              key: _keys[i],
                              child: _StoryCard(
                                index: i,
                                review: review,
                                hideAmounts: state.hideAmounts,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < _keys.length; i++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.symmetric(horizontal: 3.w),
                          width: i == _page ? 18.w : 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: i == _page
                                ? palette.accent
                                : palette.textMuted.withValues(alpha: .3),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                    ],
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
                    child: SizedBox(
                      width: double.infinity,
                      child: NeuButton(
                        label: l10n.wrapped_share,
                        icon: Icons.ios_share,
                        loading: _sharing,
                        onTap: _sharing ? null : () => _share(review.year),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.index,
    required this.review,
    required this.hideAmounts,
  });

  final int index;
  final YearInReview review;
  final bool hideAmounts;

  static const _gradients = [
    [Color(0xFF6A5AE0), Color(0xFF9B8CFF)],
    [Color(0xFFE0645A), Color(0xFFFFA48C)],
    [Color(0xFF1F9D8B), Color(0xFF6FD6C2)],
    [Color(0xFFDB8B16), Color(0xFFFFC95C)],
    [Color(0xFF2C6BD9), Color(0xFF7FB0FF)],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = context.watch<CurrencyCubit>();
    String money(double inr) {
      if (hideAmounts) return '•••';
      final v = currency.convertFromInr(inr);
      return '${currency.state.selected.symbol}'
          '${NumberFormat.decimalPattern('en_IN').format(v.round())}';
    }

    final colors = _gradients[index % _gradients.length];
    final (emoji, heading, body) = _content(l10n, money);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28.r),
      ),
      padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.wrapped_cardHeader('${review.year}'),
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: .85),
            ),
          ),
          const Spacer(),
          Text(emoji, style: TextStyle(fontSize: 44.sp)),
          SizedBox(height: 12.h),
          Text(
            heading,
            style: AppTextStyles.manrope(
              fontSize: 26.sp,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.15,
            ),
          ),
          SizedBox(height: 16.h),
          ...body,
          const Spacer(),
          Text(
            'ExpenseFlow',
            style: AppTextStyles.manrope(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: .8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _line(String text, {bool strong = false}) => Padding(
    padding: EdgeInsets.only(bottom: 8.h),
    child: Text(
      text,
      style: AppTextStyles.manrope(
        fontSize: strong ? 16.sp : 14.sp,
        fontWeight: strong ? FontWeight.w700 : FontWeight.w500,
        color: Colors.white,
        height: 1.35,
      ),
    ),
  );

  (String, String, List<Widget>) _content(
    AppLocalizations l10n,
    String Function(double) money,
  ) {
    final r = review;
    switch (index) {
      case 0:
        final change = r.changeVsLastYear;
        return (
          '💸',
          l10n.wrapped_totalHeading(money(r.total)),
          [
            _line(l10n.wrapped_transactions(r.transactions)),
            _line(l10n.wrapped_perDay(money(r.perDay))),
            if (change != null)
              _line(
                change <= 0
                    ? l10n.wrapped_lessThanLastYear(
                        (-change * 100).round(),
                        '${r.year - 1}',
                      )
                    : l10n.wrapped_moreThanLastYear(
                        (change * 100).round(),
                        '${r.year - 1}',
                      ),
                strong: true,
              ),
          ],
        );
      case 1:
        final top = r.topCategories.isEmpty ? null : r.topCategories.first;
        final topCategory = top == null
            ? null
            : ExpenseCategories.byId(top.key);
        return (
          topCategory?.emoji ?? '🏷️',
          topCategory == null
              ? l10n.wrapped_categoriesHeading
              : l10n.wrapped_topCategory(topCategory.labelOf(l10n)),
          [
            for (final c in r.topCategories)
              _line(
                '${ExpenseCategories.byId(c.key).emoji}  '
                '${ExpenseCategories.byId(c.key).labelOf(l10n)}  ·  '
                '${(c.value / r.total * 100).round()}%'
                '${hideAmounts ? '' : '  ·  ${money(c.value)}'}',
              ),
          ],
        );
      case 2:
        final biggest = r.biggestExpense;
        return (
          '🏪',
          r.topMerchant == null
              ? l10n.wrapped_biggestHeading
              : l10n.wrapped_topMerchant(r.topMerchant!),
          [
            if (r.topMerchant != null)
              _line(
                l10n.wrapped_merchantVisits(
                  r.topMerchantVisits,
                  money(r.topMerchantTotal),
                ),
              ),
            if (biggest != null) ...[
              SizedBox(height: 8.h),
              _line(l10n.wrapped_biggest, strong: true),
              _line(
                '${money(biggest.amount)} · '
                '${biggest.title ?? biggest.merchant ?? ExpenseCategories.byId(biggest.categoryId).labelOf(l10n)}'
                ' · ${DateFormat.MMMd(l10n.localeName).format(biggest.date)}',
              ),
            ],
          ],
        );
      case 3:
        final month = r.busiestMonth;
        final weekday = r.busiestWeekday;
        return (
          '📅',
          month == null
              ? l10n.wrapped_rhythmHeading
              : l10n.wrapped_busiestMonth(
                  DateFormat.MMMM(
                    l10n.localeName,
                  ).format(DateTime(r.year, month)),
                ),
          [
            if (weekday != null)
              _line(
                l10n.wrapped_busiestWeekday(
                  DateFormat.EEEE(
                    l10n.localeName,
                  ).format(DateTime(2024, 1, weekday)),
                ),
              ),
            if (r.topPaymentMethod != null)
              _line(
                l10n.wrapped_topPayment(
                  PaymentMethods.localizedLabel(l10n, r.topPaymentMethod!),
                ),
              ),
          ],
        );
      default:
        return (
          '🧘',
          l10n.wrapped_noSpendHeading(r.noSpendDays),
          [
            _line(l10n.wrapped_longestStreak(r.longestNoSpendStreak)),
            _line(l10n.wrapped_outro, strong: true),
          ],
        );
    }
  }
}
