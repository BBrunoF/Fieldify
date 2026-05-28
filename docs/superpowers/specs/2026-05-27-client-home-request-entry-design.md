# Client Home Cleanup + Trade-Tile Request Entry — Design

**Date:** 2026-05-27
**Branch:** `maps`

## Goal

Remove the non-functional placeholder widgets from the client home screen and
replace the way a job is requested with real, DB-backed trade tiles that
deep-link into the existing request flow.

## Problem

The client home (`client_home_screen.dart`) shows four widgets that are fake or
inert:
- A search bar ("What do you need fixed?" + Filter) that isn't a real input.
- An "Active job" banner with hardcoded data ("Pipe leak repair / Manuel F.").
- A "Services" category row whose taps only toggle local highlight state.
- "Quick request" cards with hardcoded ETAs/prices (`~12 min`, `from €30/h`).

## Scope

In scope:
1. Delete all four widgets and their now-dead private helper classes.
2. Add real trade tiles loaded from the database.
3. Add an optional deep-link into the request flow that preselects a trade.

Out of scope: search, filtering, real active-job surfacing, nearby-pro data.

## Decisions

- Tiles show **icon + trade name only** — no prices or ETAs.
- Tapping a tile **jumps to step 2 "Details"** of the request flow (category
  preselected; back button still returns to "Category").
- Trades are loaded via the existing `RequestRepository.getTrades()` — no new
  controller; the home holds a small `List<Trade>` loaded in `initState`.

## Changes

### 1. Home cleanup — `lib/features/client/home/presentation/screens/client_home_screen.dart`
Remove the build methods and dead private classes:
- `_buildSearchBar()` and its call in `_buildMainTab()`.
- `_ActiveJobBanner` (class + usage).
- The "Services" section: the hardcoded `categories` const, the
  `_selectedCategory` state field, and the `_SectionHeader('Services', ...)`
  block. **Keep** `_CategoryPill` and `_CategoryData` — they are reused as the
  trade tiles (icon + label, via `ServiceIconPainter`).
- The "Quick request" section: the `_RequestCard` list and the `_RequestCard`
  class.
- Any `_SectionHeader` class only if it becomes unused; keep it if the new
  tile section reuses it.

The green header column becomes `[_buildHeader(), _buildMap()]` (search bar
removed).

### 2. Trade tiles — same file
- Inject for tests: add `final RequestRepository? tradesRepository;` to
  `ClientHomeScreen`; default to `RequestRepository()`.
- State: `List<Trade> _trades = const []; bool _loadingTrades = true;
  String? _tradesError;`
- In `initState`, load trades:
  ```
  _tradesRepo.getTrades()
    -> success: _trades = result; _loadingTrades = false;
    -> failure: _tradesError = 'Could not load services.'; _loadingTrades = false;
  ```
  (guard with `mounted`.)
- New `_buildContent()` renders:
  - Heading text "What do you need fixed?".
  - If `_loadingTrades`: a small centered `CircularProgressIndicator`.
  - Else if `_trades` empty or `_tradesError != null`: a short message.
  - Else: a `Wrap` (spacing ~12) of `_CategoryPill` tiles, one per trade:
    `_CategoryPill(data: _CategoryData(trade.displayName, iconForTrade(trade.slug)),
    active: false, onTap: () => _openRequestFlow(trade))`. Wrap each in a
    `KeyedSubtree(key: Key('homeTradeTile_${trade.id}'))` for test targeting.

### 3. Deep-link — `lib/features/client/request/presentation/screens/request_screen.dart`
- Add `final int? initialTradeId;` to `RequestScreen` constructor.
- Add state `bool _appliedInitialTrade = false;`.
- In `_onRequestChanged` (fires when `loadTrades` populates `_requestCtrl.trades`),
  after the existing logic, apply once:
  ```
  if (!_appliedInitialTrade && widget.initialTradeId != null
      && _requestCtrl.trades.isNotEmpty) {
    final idx = _requestCtrl.trades.indexWhere((t) => t.id == widget.initialTradeId);
    if (idx >= 0) { _cat = idx; _step = 2; }
    _appliedInitialTrade = true;
  }
  ```
  Wrap state mutation in the existing `setState`.
- With `initialTradeId == null`, nothing changes (still starts at step 1).

### 4. Home → request wiring — `client_home_screen.dart`
Update `_openRequestFlow` to accept an optional trade and pass it through:
```
void _openRequestFlow([Trade? trade]) {
  Navigator.of(context).push(MaterialPageRoute(
    builder: widget.requestScreenBuilder
        ?? (_) => RequestScreen(initialTradeId: trade?.id),
  ));
}
```
(When `requestScreenBuilder` is injected for tests, it takes precedence as
today.)

## Error handling
- Trade load failure → inline message in the tile area, no crash; user can still
  navigate via bottom nav.
- Deep-link with an `initialTradeId` not present in the loaded trades → falls
  back to the normal Category step (idx < 0, no jump).

## Testing
- **Home:** inject a `tradesRepository` (or `requestScreenBuilder`) fake; assert
  tiles render for the fake trades and tapping `homeTradeTile_<id>` navigates
  into the request flow (verify the pushed `initialTradeId` via an injected
  `requestScreenBuilder` that records the route, or via a fake).
- **Request:** pump `RequestScreen(controller: fakeWithTrades, initialTradeId: X)`;
  after trades load, assert the "Details" step is shown and the matching
  category is selected. Existing request tests (no `initialTradeId`) stay green.

## Notes
- `iconForTrade(slug)` already exists in `trade_icon_mapper.dart` and maps
  known slugs to `ServiceIconType`, defaulting to `ServiceIconType.other`.
- `Trade` has `id`, `slug`, `displayName`, `standardRate`.
