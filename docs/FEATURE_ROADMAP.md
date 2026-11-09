# ExpenseFlow — Feature Roadmap (Priority-wise)

> **Positioning:** *A private, India-first money assistant — your data and your AI never leave your phone.*
> Every item below either strengthens that promise or removes friction that makes users quit expense trackers.

**Current strengths to build on:** on-device AI (Gemma + MiniLM RAG with a safety gate), offline-first Hive storage with Firestore sync and conflict status, and Hindi/Marathi localization.

---

## Priority legend

| Priority | Meaning |
|---|---|
| **P0** | Foundation. Must be done before marketing anything else. |
| **P1** | High impact, core differentiators. Build next. |
| **P2** | Strong value-adds that deepen engagement. |
| **P3** | Nice-to-have, growth & polish. |

Effort: **S** (≤ 3 days) · **M** (1–2 weeks) · **L** (2+ weeks)

---

## P0 — Foundations ✅ Done (Nov 2026)

| # | Item | Area | Status | What shipped |
|---|---|---|---|---|
| 0.1 | Replace broken default test; add unit tests | Quality | ✅ | 78 tests: validation, recurrence math, recurring generation, budget alerts, AI safety & cosine similarity, app lock cubit, model serialization, encrypted-storage migration. Found and fixed an AI safety bug (substring matching refused "taxi" as tax, "premium" as EMI). |
| 0.2 | Encrypt Hive boxes at rest | Security | ✅ | `SecureHive` opens every box AES-256 encrypted; key in Keystore/Keychain via `flutter_secure_storage`; one-time migration of legacy plaintext boxes. |
| 0.3 | Biometric / PIN app lock | Security | ✅ | `features/app_lock`: settings toggle, lock on cold start and after 30s in background, device-PIN fallback. |
| 0.4 | `merchant` field on expenses | Data model | ✅ | Hive field 15, synced to Firestore, add/edit/detail UI, used by AI chunks. |
| 0.5 | Original amount + currency + FX rate | Data model | ✅ | `originalAmount` / `exchangeRate` (fields 16–17); editing no longer re-converts an unchanged amount at today's rate. |
| 0.6 | Recurring expense model | Data model | ✅ | `features/recurring`: rules, month-end-safe date math, launch-time generation (idempotent), "Repeat" on add screen, management screen. Rules are local-only for now. |
| 0.7 | Fix README | Docs | ✅ | Accurate features, stack, setup (`.env` keys), structure, testing. |

## P1 — Core differentiators ✅ Done (Nov 2026)

| # | Item | Status | What shipped |
|---|---|---|---|
| 1.1 | UPI / bank SMS auto-capture | ✅ | `features/sms_capture`: native inbox reader (method channel in `MainActivity`), on-device parser for HDFC/ICICI/SBI/Axis/Kotak-style debit SMS (rejects credits, OTPs, promos, reminders, failed/ATM, personal-number senders), incremental scan on launch/resume, review queue with dedupe and "already logged?" flag, Play prominent-disclosure dialog. **Needs a Play Console SMS permissions declaration before release.** |
| 1.2 | Pace-based budget alerts | ✅ | `BudgetProgressCalculator`: period-aware spend, projected run-out date, pace notification (once per period). Budget screen shows pace per category. Fixed: budget and dashboard "this month" totals were summing all-time spend. |
| 1.3 | "Safe to spend today" | ✅ | Dashboard card: Σ budget daily allowances after upcoming recurring bills. |
| 1.4 | Subscription detector | ✅ | Weekly/monthly/yearly detection with amount tolerance, lapse detection, "Auto-log" → recurring rule, AI chunks. |
| 1.5 | Savings goals | ✅ | `features/goals`: create, deposit/withdraw, per-day target, on-track/behind, AI chunks. Local-only. |
| 1.6 | RAM-based AI fallback | ✅ | `AdaptiveAnswerStrategy`: Gemma ≥ 3 GB RAM, otherwise retrieval-only "lite" answers; also falls back if Gemma fails before answering. |
| 1.7 | Custom categories | ✅ | Create/edit/archive with emoji + colour, synced via `settings/{uid}`; usable in pickers, budgets, charts and AI. Sub-categories not done (deferred). |
| 1.8 | Auto-categorization by merchant | ✅ | `CategorySuggester`: own history → similar merchant → Indian merchant dictionary; live in Add Expense and SMS capture. Embedding-based matching not used. |

## P2 — Engagement & depth ✅ Done (Nov 2026)

| # | Item | Status | What shipped |
|---|---|---|---|
| 2.1 | Multilingual voice entry ("चहा 20 रुपये") | ✅ | `features/voice_entry`: mic button on Add Expense → `speech_to_text` in en-IN / hi-IN / mr-IN (switchable in the sheet). **On-device recognition by default**; if the offline language pack is missing the user can explicitly opt into online recognition (disclosed in the sheet). `VoiceExpenseParser` extracts amount (Devanagari digits, हजार/शंभर/दीड multipliers, "rupees" detection), payment method, category (Hindi/Marathi/English keywords + merchant dictionary + own history) and title instantly; Gemma refines only missing fields, and its output is validated against the transcript (no invented amounts/merchants). Fills the form for review, never auto-saves. |
| 2.2 | Proactive weekly AI digest | ✅ | Deterministic facts → Gemma rewrite (RAM-gated, cached, ≤ once per 12 h, faithfulness-checked) → Monday notification + in-app inbox once per week. Startup refresh is now actually wired (it was registered but never called). |
| 2.3 | "Can I afford it?" mode | ✅ | `AnswerAffordabilityUseCase` answers before RAG via `directAnswer`, using remaining budget, pace, upcoming bills and goals. |
| 2.4 | Monthly PDF statement + CSV/Excel export | ✅ | `features/reports`: Settings → Statements & export. A4 PDF (totals, vs-last-month, category & payment breakdown, all transactions, tax tags) with bundled Noto Sans + Devanagari (OFL, `assets/fonts/`) so ₹ and Hindi/Marathi render offline. CSV by range (this/last month, FY, all time): UTF-8 BOM for Excel, RFC 4180 quoting, CSV-injection guard. Shared via the system sheet from the temp dir. |
| 2.5 | Indian tax tagging (80C / 80D / HRA / 80G / 80E) | ✅ | Tax chips on add/edit (auto-suggested from title/merchant/note, e.g. "LIC premium" → 80C), shown on detail, carried by recurring rules, synced (`taxTag`, Hive field 19). Settings → Tax deductions: per-FY summary with statutory caps, remaining room, expandable expense lists, CSV export. AI transaction chunks mention the section. Fixed: editing an expense silently dropped its tag. |
| 2.6 | Bill & EMI reminders | ✅ | `BillReminderPlanner` schedules day-before reminders from recurring rules; toggle in notification settings. |
| 2.7 | Actionable notifications | ✅ | After an SMS scan, fresh (≤ 24 h, non-duplicate) payments get "₹120 at Swiggy — Add as Food? **[OK] [Change]**"; >3 collapse into one summary. OK logs through the same `ExpenseBloc` path as the review screen; Change opens the queue. Works from a cold start. "Detected payments" toggle in notification settings. Android only (action buttons). |
| 2.8 | Payment-method breakdown chart | ✅ | Dashboard card. |
| 2.9 | Calendar heatmap + no-spend streaks | ✅ | Dashboard card with month heatmap, no-spend days and best run. |
| 2.10 | Budget rollover | ✅ | Per category (edit budget screen): Off / Carry forward / Move into a savings goal. Carry-forward raises the effective limit everywhere (budget screen shows "includes ₹X rolled over", alerts, digest, safe-to-spend). Goal transfers settle at launch, idempotently per period; switching to a goal never sweeps an already-closed period; a deleted goal turns rollover off. |
| 2.11 | Hybrid retrieval (lexical + vector) | ✅ | `HybridRetrievalService` fuses lexical and vector scores. |

**Known limits:** the `pdf` package doesn't do complex-script shaping, so some Devanagari conjuncts/matras in PDF statements may render imperfectly (glyphs are correct, ligatures aren't). Voice entry quality depends on the device's speech recogniser; Marathi offline packs aren't installed by default on most phones.

---

## P3 — Growth & polish ✅ Done (Nov 2026)

| # | Item | Status | What shipped |
|---|---|---|---|
| 3.1 | Home screen widgets | ✅ | `features/home_widget`: "Safe to spend today" widget with a quick-add button (`home_widget`). Android `SafeToSpendWidget` (Kotlin + XML, en/hi/mr strings) and an iOS WidgetKit extension (`ios/SafeToSpendWidget`, see `docs/HOME_WIDGETS.md`). Pushed whenever budget insights change; **amounts are hidden while app lock is on**; stale data shows "open app". Taps deep-link to Add Expense / Dashboard. |
| 3.2 | Shared / household budgets & split expenses | ✅ | `features/groups`: Firestore groups (household, roommates, trip, other) with an optional shared monthly budget, 6-character invite codes valid for 7 days, equal or custom splits in integer paise, balances and "settle up" suggestions (at most n−1 payments), recorded payments, and "add my share to my expenses" so personal budgets stay right. `firestore.rules` restrict reads to members, joins to valid unexpired invites (max 20 members), and leaving to removing yourself. Needs sign-in; personal data stays local. |
| 3.3 | On-device receipt scanning | ✅ | `features/receipt_scan`: camera/gallery → **Google ML Kit text recognition (on-device)** → `ReceiptParser` (total by keyword priority, GST, day-first dates, merchant, line items, payment method) → review sheet where items can be unticked → fills Add Expense. The photo never leaves the phone; camera shots are deleted after reading. |
| 3.4 | Festival / event budgets | ✅ | `features/events`: Diwali/wedding/other events with a date range, budget and optional category scope; progress, daily pace and projected total; expenses auto-suggest the active event on Add Expense. Optionally "separate from monthly budgets" (`BudgetExpenseFilter`). |
| 3.5 | Trip mode | ✅ | Trips are events with their own currency: Add Expense switches to the trip currency while the trip is active, converts with the stored rate, and shows spend in both currencies. Trips default to separate from monthly budgets. |
| 3.6 | Year-in-review ("Wrapped") | ✅ | `features/insights` `YearInReview` + five story cards (total, top categories, top merchant, biggest month/expense, no-spend streaks, vs last year). Each card shares as a PNG; an "hide amounts" toggle is available before sharing. Computed on-device; needs ≥10 expenses in the year. |
| 3.7 | Smart logging reminders | ✅ | `LoggingTimeLearner`: 30-minute buckets, 21-day half-life over 60 days of `createdAt`; needs 8 entries over 5 days, else 21:00. Clamped 08:00–22:30, rounded to 15 min. Reminders are skipped on days you've already logged and rescheduled (debounced) as expenses change. |
| 3.8 | Charts inside AI answers | ✅ | `AnswerChartPlanner` detects chart-worthy questions (en/hi/mr keywords): category breakdown, 6-month trend, daily spend, budget usage. Charts are built **from your data, never from model output**, and rendered with fl_chart under the answer. A chart failure never fails the answer. |
| 3.9 | Envelope / zero-based budgeting | ✅ | Optional mode (Settings → Envelopes): set monthly income, assign it to monthly budgets, see "to be assigned", move money between envelopes; unspent money and overspending carry forward. Replaces rollover for monthly budgets while on. |
| 3.10 | Vector index + quantized embeddings | ✅ | `VectorIndex`: int8 quantisation, exact search up to 512 chunks, IVF (spherical k-means, √n lists) from 2,000 chunks probing 15% of lists, exact re-scoring of the top 64. `VectorIndexCache` rebuilds large indexes in an isolate and serves the stale index plus exact scores for changed chunks meanwhile. Recall@5 ≥ 0.95 in tests. |

**Known limits:**
- **On-device model.** The bundled model is text-only (Qwen2.5-0.5B), so receipts use ML Kit OCR instead of Gemma 3n vision.
- **Receipt parsing.** Parsing is rule-based and tuned for Indian bills. Handwritten bills and heavily stylised receipts may need manual fixes.
- **iOS widget.** The widget extension target must be added in Xcode once (`docs/HOME_WIDGETS.md`).
- **Groups.** These need network and sign-in. Deleting a group leaves its expense subcollection orphaned; it becomes unreadable, but nothing cleans it up.
- **Firestore rules.** These must be deployed: `firebase deploy --only firestore:rules`.
- **Envelope mode.** It covers monthly budgets only.

---|---|---|---|---|
| 3.1 | **Home screen widgets** (quick-add, safe-to-spend) | Dashboard | M | Android + iOS. Drives daily engagement. |
| 3.2 | **Shared / household budgets & split expenses** | Social | L | Firestore-backed groups for roommates, trips, joint families. Splitwise splits but doesn't budget. |
| 3.3 | **On-device receipt scanning** (Gemma 3n vision) | Capture | L | Offline OCR of bills into line items. |
| 3.4 | **Festival / event budgets** (Diwali, weddings) | Budget | S | Temporary budgets spanning categories. |
| 3.5 | **Trip mode** with its own budget & currency | Budget / Currency | M | Depends on 0.5. |
| 3.6 | **Year-in-review ("Wrapped")** shareable card | Growth | M | Generated on-device; free marketing. |
| 3.7 | **Smart logging reminders** at the user's usual time | Notifications | S | Learn from `createdAt` patterns. |
| 3.8 | **Charts inside AI answers** | AI | M | Render a small fl_chart alongside the text response. |
| 3.9 | **Envelope / zero-based budgeting mode** | Budget | M | Optional mode for disciplined users. |
| 3.10 | **Vector index + quantized embeddings** | AI perf | M | Replace brute-force `scoreAll` when chunks exceed ~10k (`AI_ARCHITECTURE.md` §9). |

---

## Suggested execution order

1. **Sprint 1 — P0:** tests, encryption, app lock, `merchant` field, recurring model, README.
2. **Sprint 2 — Quick wins:** 1.2 pace alerts, 1.3 safe-to-spend, 1.7 custom categories.
3. **Sprint 3 — AI value:** 1.4 subscriptions, 1.5 savings goals, 1.6 RAM fallback, 1.8 auto-categorization.
4. **Sprint 4 — Headline feature:** 1.1 SMS auto-capture + 2.7 actionable notifications.
5. **Sprint 5 — P2 (done):** export, tax tagging, rollover, actionable notifications, voice entry.
6. **Sprint 6 — P3 (done):** widgets, groups, receipts, events/trips, Wrapped, smart reminders, AI charts, envelopes, vector index.

## Dependency map

```
0.4 merchant ──► 1.1 SMS capture ──► 2.7 actionable notifications
            ├──► 1.4 subscriptions
            └──► 1.8 auto-categorization
0.5 original currency ──► 3.5 trip mode
0.6 recurring model ──► 1.3 safe-to-spend
                   ├──► 1.4 subscriptions
                   └──► 2.6 bill/EMI reminders
1.5 savings goals ──► 2.10 rollover
```
