# Pro Home Dashboard — Design

**Date:** 2026-05-26

## Goal

Replace the "Your pro dashboard is on the way" placeholder in the pro home
screen's main tab with a real stats dashboard: four metric cards in a 2×2 grid,
matching the existing mockup. The dark green header (Fieldify bar + "Welcome
back") is unchanged. No active-job card, no nearby-requests list.

## Location

Lives in the existing `lib/features/pro/home/` slice (the dashboard *is* the
pro home content), following the project's Screen→Controller→Repository→Service
layering:

```
lib/features/pro/home/
  presentation/screens/pro_home_screen.dart       # existing — placeholder replaced
  presentation/widgets/pro_dashboard_view.dart     # new — 2×2 grid + _StatCard
  controllers/pro_dashboard_controller.dart         # new — ChangeNotifier
  data/models/pro_dashboard_stats.dart              # new — value object
  data/repositories/pro_dashboard_repository.dart   # new
  data/services/pro_dashboard_service.dart          # new — Supabase queries
```

The controller is passed in optionally through `HomeScreen` → `ProHomeScreen`
(same pattern as the existing `jobsController`) for testability. When not
provided, `ProHomeScreen` constructs a default one.

## The four cards

All scoped to the current authenticated user as `pro_id`.

| Card | Big number | Subtitle | Source |
|------|-----------|----------|--------|
| This month | `€` sum of `amount_charged` where `status='captured'`, `captured_at` in current month | "+X% vs last month" (real; hidden when last month = 0) | `payments` |
| Jobs completed | count of `service_requests` `status='completed'` all-time | "{n} this month" | `service_requests` |
| Your rating | average rating, 1 decimal | "based on {n} reviews" / "No reviews yet" when count = 0 | `reviews` |
| Acceptance rate | accepted ÷ (accepted + rejected) over last 30 days, as % | "Last 30 days" | `service_requests.accepted_at` + `service_request_rejections` |

## Data model

`ProDashboardStats` (immutable value object):

- `double earningsThisMonth`
- `double earningsLastMonth`
- `int jobsCompletedAllTime`
- `int jobsCompletedThisMonth`
- `double ratingAverage`
- `int ratingCount`
- `double? acceptanceRate` — null when there were no accepted/rejected events
  in the window; the card renders "—".

Derived getter `int? earningsChangePercent` — null when `earningsLastMonth` is
0, else the rounded percentage change.

`ProDashboardStats.empty` provides all-zero defaults for the loading/error path.

## Queries (service)

1. **Earnings** — one query on `payments`: select `amount_charged, captured_at`
   where `pro_id = me`, `status = 'captured'`, `captured_at >= start of last
   month`. Sum into this-month and last-month buckets in Dart.
2. **Jobs completed** — select `completed_at` from `service_requests` where
   `pro_id = me`, `status = 'completed'`. Count all + count this month in Dart.
3. **Rating** — select `rating` from `reviews` where `pro_id = me`. Average +
   count in Dart.
4. **Acceptance rate** — two count queries over the last 30 days: accepted =
   `service_requests` where `pro_id = me`, `accepted_at >= now-30d`; rejected =
   `service_request_rejections` where `pro_id = me`, `created_at >= now-30d`.
   `rate = accepted / (accepted + rejected)`; null when denominator is 0.

Queries run concurrently with `Future.wait`. The service composes them into one
`ProDashboardStats`.

## States

- **Loading:** spinner centered in the body area (header already shown).
- **Error / brand-new pro:** controller swallows errors (per existing `_load()`
  pattern) and falls back to `ProDashboardStats.empty`, so cards render `€0`,
  `0`, "No reviews yet", "—" rather than blocking.

## Styling

White cards, `BorderRadius.circular(16)`, `FieldifyColors.border` hairline;
label in `ink3`, big number in `ink`, subtitle in `g500`. 2×2 grid with even
spacing, matching the mockup and the existing token system.

## Testing

- Controller test with a fake repository (mirrors `pro_profile_controller_test`):
  verifies loading flag, stats exposure, and error → empty fallback.
- Widget test for `pro_dashboard_view`: renders each metric, the "No reviews
  yet" and "—" empty states, and the month-over-month line visibility.
