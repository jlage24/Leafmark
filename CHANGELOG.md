# Changelog

All notable changes to LeafMark will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [0.3.0] - 2026-05-15 — Sprint 2 Release

### Added
- In-app chat system (Vinted-style) with swap proposals, counter-offers, typing indicators and read receipts
- `ChatListScreen` as inbox in the bottom nav Chat tab
- Book picker bottom sheet to select offered book before creating a swap
- `PublicProfileScreen` accessible from chat with another user
- User profile bio, profile photo and Top 3 Favourite Authors (Firestore-persisted)
- `EditProfileScreen` with multiline bio, photo upload and author fields
- Rating system — rate trading partner (1–5 stars) and book condition after a completed swap
- `RateExchangeScreen` with duplicate submission prevention (`hasRated` guard)
- Exchange history screen listing all successfully completed swaps with cover, title, partner and date
- Report profile feature — flag suspicious users via bottom sheet (Spam / Inappropriate behaviour / Fake account / Other)
- Public wishlist — users can create and share a list of books they want to acquire
- `WishlistScreen` with long-press-to-delete and add by title/author/ISBN
- Wishlist visible in read-only mode on `PublicProfileScreen`
- Unit tests for `WishlistService` and `RatingService` using `FakeFirebaseFirestore`
- UATs for rating flow and exchange history

### Changed
- `BrowseScreen` fully migrated from dummy data to Firestore via `collectionGroup('shelf')`
- `SwapRequestsScreen` migrated from dummy data — now shows real cover, title and `displayName`
- `BookShelfProvider.addBook` now persists `ownerId` and `ownerName` to Firestore
- Swap request flow moved from `ProfileScreen` menu to Chat tab
- `ProfileScreen` menu extended with Exchange History and My Wishlist entries
- Made the suggested changes to the Logical Architecture UML

### Removed
- Dummy data from `BrowseScreen` and `SwapRequestsScreen` (fully replaced by Firestore)

### Security
- Firestore security rules added for `ratings`, `reports` and `users/{uid}/wishlist` collections

### Known Limitations
- GitHub Release asset upload still triggered manually due to org-level Actions permissions (403)

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