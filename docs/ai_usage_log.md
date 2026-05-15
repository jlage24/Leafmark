# AI Usage Log

This document tracks how AI tools were used throughout the development of LeafMark.

All five team members used AI assistants at various points. The tools were **Claude** (primary), **Gemini**, **ChatGPT** and **Perplexity**. Every suggestion was read and understood before being applied — nothing was copied blindly into the codebase.

---

## Tools

| Tool | Primary use |
|---|---|
| Claude | Architecture decisions, implementation guidance, code review, documentation |
| Gemini | Flutter-specific questions, second opinions on UI patterns |
| ChatGPT | Alternative approaches, debugging help |
| Perplexity | Quick research, package comparisons, Firebase documentation lookups |

---

## Sprint 0

**Architecture and project setup**
- Used Claude to discuss and validate the feature-first folder structure (`features/{name}/data/domain/presentation`) before committing to it
- Used Claude to decide between `shared_preferences` and Firestore for Sprint 0 persistence — landed on `shared_preferences` for the prototype with a planned migration in Sprint 1
- Used Perplexity to compare `mobile_scanner` vs other barcode packages

**Implementation**
- Used Claude to work through the `BookShelfProvider` design and catch a silent double-registration bug that caused two independent provider instances
- Used Gemini for questions about Flutter's `CachedNetworkImage` configuration
- Used ChatGPT for help structuring the cover image fallback chain (Google Books → `smallThumbnail` → OpenLibrary)

**Testing**
- Used Claude to structure the unit, integration and acceptance test suites
- Used Claude to fix `flutter analyze` warnings across `AddBookScreen`, `IsbnScannerScreen` and error builders

**Documentation**
- Used Claude to draft the initial README structure and domain model descriptions

---

## Sprint 1

**Firebase migration**
- Used Claude extensively to plan and implement the full migration from `shared_preferences` to Firestore — including the `users/{uid}/shelf/{bookId}` path design and security rules
- Used Claude to debug a Firestore path mismatch between the provider and security rules that was silently failing
- Used Claude to implement the username system with atomic batch writes to `/usernames/`

**Implementation**
- Used Claude to design the `BookShelfProvider` constructor injection pattern for testability with `FakeFirebaseFirestore`
- Used Gemini for questions about Firebase Auth `displayName` persistence
- Used ChatGPT for help with the `use_build_context_synchronously` warning pattern across async gaps

**CI/CD**
- Used Claude to write and debug the `release.yml` GitHub Actions workflow for automated APK builds on version bumps
- Used Perplexity to research the GitHub org permissions issue causing 403s on automated release uploads

**Testing**
- Used Claude to set up `FakeFirebaseFirestore` in tests and structure the `BookShelfProvider` test suite

---

## Sprint 2

**Chat system**
- Used Claude to design the Firestore data model for the chat (`chats/{swapId}`, `chats/{swapId}/messages/{id}`) before writing any code
- Used Claude to implement typing indicators and read receipts cleanly within the existing Provider architecture
- Used Gemini for questions about Flutter stream handling with multiple Firestore listeners

**Ratings, wishlist and reports**
- Used Claude to define the `ratings`, `reports` and `users/{uid}/wishlist` Firestore schemas and corresponding security rules
- Used Claude to work through the `hasRated` guard to prevent duplicate rating submissions
- Used ChatGPT for alternative approaches to the `RateExchangeScreen` star widget

**Firestore migration**
- Used Claude to migrate `BrowseScreen` and `SwapRequestsScreen` from dummy data to `collectionGroup('shelf')` queries

**Testing**
- Used Claude to write unit tests for `WishlistService` and `RatingService` using `FakeFirebaseFirestore`
- Used Perplexity to look up UAT best practices for mobile apps

**Documentation**
- Used Claude to write and refine the CHANGELOG, README setup guide, sprint retrospectives and this log