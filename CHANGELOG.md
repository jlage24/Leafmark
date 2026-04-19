# Changelog

All notable changes to LeafMark will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.2.0] - 2026-04-19 — Sprint 1 Release

### Added
- User account creation and authentication via Firebase Auth
- Trade status management — mark a swap as "In Progress" or "Completed"
- Accept/reject swap requests as a book owner
- Search books by title, author, and ISBN
- Cached network images in `BookCard` for improved performance
- Full Firebase backend integration (Firestore + Firebase Auth + Firebase Storage)

### Changed
- Migrated persistence layer from `shared_preferences` to Firestore
- UI enhancements across multiple screens

### Removed
- Local-only `shared_preferences` persistence (replaced by Firebase)

### Known Limitations
- Trust/safety features (peer ratings, report user, secure chat) identified as Must Have but not yet implemented

## [0.1.0] - 2026-04-05 — Sprint 0 Release

### Added
- ISBN barcode scanner via `mobile_scanner` with Google Books API lookup
- `BookShelfProvider` with `shared_preferences` persistence
- `MyShelfScreen` with book list and long-press-to-delete flow
- Bottom sheet delete confirmation with haptic feedback and snackbar
- `BrowseScreen` with 32 dummy books using OpenLibrary covers
- `BookDetailScreen` with condition chips, notes, and swap placeholder
- `MainScreen` navigation shell with 2 tabs and FAB
- Cover image fallback chain: Google Books → `smallThumbnail` → OpenLibrary
- GitHub Actions CI workflow (analyze, test, build on push/PR to `dev`/`main`)
- Unit tests for `Book` model and `BookShelfProvider`
- Integration tests for provider ↔ persistence wiring
- Acceptance/widget tests for `MyShelfScreen` user interactions
- MoSCoW-labelled backlog with 19 user stories as GitHub Issues
- Git Flow branching strategy with branch protection on `main` and `dev`

### Fixed
- Resolved duplicate `BookShelfProvider` registration in `main.dart` that caused
  two independent provider instances and silent state desync
- Corrected broken import path on scanner feature branch (reverted rewrite,
  applied minimal targeted fix)
- Resolved `Book` model conflict between parallel feature branches by adopting
  the richer schema with `toJson`/`fromJson`, enums, and timestamps as canonical
  - Resolved all `flutter analyze` warnings: removed unnecessary cast in
  `BookFetchResult`, replaced deprecated `withOpacity` with `withValues`
  across `AddBookScreen`, `IsbnScannerScreen`, and fixed unnecessary
  multiple underscores in error builders across all screens

### Security
- Google Books API key injected via `--dart-define-from-file`; `.env` excluded
  from version control via `.gitignore`

### Known Limitations
- Swap request flow is a placeholder snackbar — real flow planned for Sprint 1
- No authentication or user accounts yet
- Trust/safety features (ratings, reporting, secure chat) identified as Must Have
  in backlog but not yet implemented