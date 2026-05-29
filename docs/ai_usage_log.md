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

---

## Sprint 3

**Core feature implementation**

* Used Gemini to discuss UI approaches for the redesigned `SearchScreen`, including the Books / Users segmented search experience
* Used Gemini to explore user discovery patterns and profile navigation flows
* Used ChatGPT to review the architecture for the user search implementation and Firestore query structure
* Used ChatGPT to validate dependency injection approaches for `UserSearchService` and improve testability

**Exchange workflow redesign**

* Used ChatGPT to analyse the complete physical exchange workflow and identify missing states between swap acceptance and exchange completion
* Used ChatGPT to review ownership transfer logic and ensure consistency between book shelves after completed exchanges
* Used Gemini to discuss UX implications of book locking and exchange completion flows

**Notifications, follows and blocking**

* Used Gemini to discuss social interaction patterns, follow relationships and notification UX
* Used Claude/Gemini-style reasoning (second-opinion workflow) to compare different Firestore structures for notifications and follows before implementation
* Used ChatGPT to review security implications of blocking users and swap restrictions

**Firestore and security rules**

* Used ChatGPT to analyse Firestore permission issues affecting follows, notifications, completed swaps and public profile statistics
* Used Gemini to verify best practices for Firestore security rule organisation and collection access patterns

**Testing and debugging**

* Used ChatGPT extensively to debug failing service tests involving `FakeFirebaseFirestore`
* Used ChatGPT to review `SwapService`, `ChatService`, `BrowseService` and `UserSearchService` test coverage
* Used ChatGPT to identify dependency injection improvements that simplified testing
* Used Gemini for Flutter testing questions and mocking strategies

**Bug fixing**

* Used ChatGPT to investigate and resolve:

    * Issue #95 (empty books could be added)
    * Issue #96 (login Enter key submission)
    * Exchange history loading issues
    * Public profile statistics issues
    * Chat flow issues after swap acceptance

**Release preparation**

* Used ChatGPT to assist with:

    * Sprint 3 release planning
    * CHANGELOG preparation
    * README review
    * Release notes drafting
    * Final release checklist validation

**Validation**

All AI-generated suggestions were manually reviewed, adapted and tested before being committed. AI tools were used as implementation assistants and reviewers, not as a replacement for development, testing or design decisions.
