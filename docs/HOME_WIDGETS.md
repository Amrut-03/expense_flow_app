# Home screen widgets

ExpenseFlow ships one widget, **Safe to spend today**. It shows:

- today's safe-to-spend amount and today's spend;
- a **+** button that opens Add Expense.

| Piece | Location |
|---|---|
| Snapshot (what the widget shows) | `lib/features/home_widget/domain/home_widget_snapshot.dart` |
| Push + tap routing (`home_widget`) | `lib/features/home_widget/data/home_widget_sync.dart` |
| Android provider | `android/app/src/main/kotlin/com/nextgen/expenseflow/SafeToSpendWidget.kt` |
| Android layout / info | `android/app/src/main/res/layout/widget_safe_to_spend.xml`, `res/xml/safe_to_spend_widget_info.xml` |
| iOS WidgetKit source | `ios/SafeToSpendWidget/SafeToSpendWidget.swift` |

## Data contract

The app writes these keys whenever budget insights or the app-lock state change. On Android they go to `HomeWidgetPreferences`; on iOS they go to the `group.com.nextgen.expenseflowapp` App Group's `UserDefaults`.

| Key | Type | Meaning |
|---|---|---|
| `date` | String `yyyy-MM-dd` | Day the values are for. If it isn't today, the widget shows "Open the app". |
| `safe` | String | Formatted safe-to-spend amount; empty when there are no budgets. |
| `spent` | String | Formatted spend today. |
| `over` | bool | Over budget, so the amount is drawn in the danger colour. |
| `hidden` | bool | App lock is on, so amounts are hidden. |

The widget uses two deep links, both of which `HomeWidgetSync.taps` routes with go_router:

- `expenseflow://add-expense?homeWidget` opens `/add-expense`.
- `expenseflow://open?homeWidget` opens `/dashboard`.

## Android

The widget is wired up already: the receiver is in `AndroidManifest.xml` and the strings are in `values`, `values-hi` and `values-mr`. Long-press the home screen, open Widgets, then pick ExpenseFlow.

## iOS (one-time Xcode setup)

The Swift source is in the repo, but the extension target can't be added from the command line.

1. Open `ios/Runner.xcworkspace` in Xcode.
2. Choose **File ▸ New ▸ Target ▸ Widget Extension** and set it up:
   - Name it `SafeToSpendWidget`.
   - Untick "Include Live Activity" and "Include Configuration App Intent".
   - When Xcode asks to activate the scheme, choose **Activate**.
3. Delete the Swift files Xcode generated in the new group. Then add `ios/SafeToSpendWidget/SafeToSpendWidget.swift` to the **SafeToSpendWidget** target only.
4. Set the extension's **Minimum Deployments** to iOS 15.5 or later, to match Runner.
5. Under **Signing & Capabilities**, add **App Groups** to **both** Runner and SafeToSpendWidget, and tick `group.com.nextgen.expenseflowapp`. Register the group in the Apple Developer portal if Xcode asks.
6. Check that the extension's bundle id is `com.nextgen.expenseflowapp.SafeToSpendWidget`.
7. Run `cd ios && pod install`, then build Runner.

The `expenseflow` URL scheme is already registered in `ios/Runner/Info.plist`.

## Privacy

- **App lock:** while it's on, the widget shows only "Open ExpenseFlow" and the **+** button, never amounts.
- **No network:** the widget only reads values the app wrote on the device.
