# LeafMark Development Report

Welcome to the documentation of **LeafMark**!

This Software Development Report, tailored for LEIC-ES-2025-26, provides comprehensive details about **LeafMark**, a collaborative book-sharing mobile application, starting from a high-level vision and going into low-level implementation decisions.

It is organised by the following activities:

* [Business Modelling](#Business-Modelling)
    * [Product Vision](#Product-Vision)
    * [Features and Assumptions](#Features-and-Assumptions)
* [Requirements](#Requirements)
    * [User Stories](#User-Stories)
    * [Domain Model](#Domain-Model)
    * [User Interfaces](#User-Interfaces)
* [Architecture and Design](#Architecture-and-Design)
    * [Logical Architecture](#Logical-Architecture)
    * [Physical Architecture](#Physical-Architecture)
    * [Functional Prototype](#Functional-Prototype)
* [Project Management](#Project-Management)
    * [Sprint 0](#Sprint-0)
    * [Sprint 1](#Sprint-1)
    * [Sprint 2](#Sprint-2)
    * [Sprint 3](#Sprint-3)
    * [Final Release](#Final-Release)

Contributions are expected to be made exclusively by the initial team, but we may open them to the community, after the course, in all areas and topics: requirements, technologies, development, experimentation, testing, etc.

Please contact us!

Thank you!

* David Pinto - up202404233@up.pt
* Diogo Quaresma - up202406470@up.pt
* João Lage - up202406458@up.pt
* Luís Torrão - up202406471@up.pt
* Mafalda Pacheco - up202406162@up.pt

---

## Business Modelling

Business modeling in software development involves defining the product's vision, understanding market needs, aligning features with user expectations, and setting the groundwork for strategic planning and execution.

### Product Vision

Leafmark is a community-driven book exchange platform that makes trading books between readers effortless, affordable, and sustainable.

### Features and Assumptions

_[List the initial high-level features of LeafMark, e.g.:_
- _Feature X — brief description_
- _Feature Y — brief description_

_Optionally, list assumptions about the app and its dependencies on external systems.]_

---

## Requirements

### User Stories
* **ISBN Barcode Scanning**: As a user with many books to add, I want to scan the barcode (ISBN) of a physical book using my camera, So that the book details (title, author, cover) are filled in automatically.
* **Initiating a Trade Request**: As a borrower, I want to propose a "swap" (my Book A for your Book B), so that we can reach a mutual agreement on the value of the trade.
* **Personal Catalog Organization**: As a user who wishes to swap books, I want to add books to my virtual shelf, so that I can keep my collection organized and choose books for future swaps.
* **Community Browsing**: As a user, I want to browse books available from other users so that I can find books I'd like to acquire.

### Domain Model

* **User**: A member of the LeafMark community who maintains a profile, tracks their rating, and manages their personal book collections.
* **Book**: A physical item defined by its title, author, and ISBN. It includes metadata such as current condition and photos to facilitate fair trading.
* **Shelf**: A collection belonging to a specific user that contains the books they currently own and are available for exchange.
* **SwapRequest**: A formal proposal that connects two users and involves the exchange of two or more books.
* **Wishlist**: A personal list belonging to a user that contains the titles of books they are actively looking to acquire.
* **Rating**: A feedback mechanism where one user evaluates another after a trade is completed to maintain community trust.

![Domain Model Diagram](docs/diagrams/DomainModel.png)

### User Interfaces

_[Add mockups or drafts of the main user interfaces for LeafMark's key screens.]_

---

## Architecture and Design

### Logical Architecture


<p align="center">
  <img src="docs/diagrams/Logical-Architecture-UML.drawio.png" alt="Logical Architecture"/>
</p>

**Package Descriptions and Dependencies:**

- **UI Layer** — Responsible for user interaction: screens, widgets, navigation. Communicates with Business Logic.
- **Business Logic Layer** — Contains use cases and state management. Coordinates between UI and Data Layer.
- **Data Layer** — Handles data access and persistence. Uses Domain entities to structure the data.
- **Domain Layer** — Defines core entities like `Book`, `User`, `SwapRequest`. Independent layer; does not depend on any other layer.

**Dependencies (arrows in diagram):**
- UI → Business Logic (uses)
- Business Logic → Data (uses)
- Data → Domain (uses)

### Physical Architecture


<p align="center">
  <img src="docs/diagrams/Physical-Architecture-UML.drawio.png" alt="Physical Architecture"/>
</p>

**Node Descriptions and Connections:**

- **Mobile App (Flutter)** — Client-side application running on Android (and eventually iOS). Handles UI, user interactions, and communication with backend and external API.
- **Firebase Backend** — Provides Firestore (database), Firebase Auth (authentication), Firebase Storage (book images). Fully managed, scalable.
- **Google Books API** — Retrieves book information from ISBN codes via HTTP.

**Connections:**
- Mobile App → Firebase: SDK calls
- Mobile App → Google Books API: HTTP requests


### Technology Justification

Flutter was chosen because it enables cross-platform mobile development with a single codebase, which is especially valuable for a small team of five developers working under tight sprint deadlines. It allows rapid iteration and consistent UI development across platforms.

Firebase is a suitable backend solution for Leafmark because it provides a fully managed and scalable infrastructure without requiring server maintenance, which reduces development overhead during early project stages. Features like Firebase Authentication are particularly useful for handling user identity and trust in a community-driven platform where users exchange books.

For the current prototype (Sprint 0), local storage is sufficient to demonstrate the core functionality. However, Firebase will support future features such as user accounts, swap requests, and real-time interactions between users.

Additionally, the Google Books API allows automatic retrieval of book data from ISBN codes, which is central to Leafmark’s core user flow and significantly simplifies the user experience.

### Functional Prototype

The functional prototype developed in Sprint 0 focuses on validating the core interaction flow of Leafmark.

- Users can scan ISBN barcodes with the camera, fetching book information automatically from Google Books API.
- Books are added to the virtual shelf and can be browsed by other users.
- Basic swap request flow is implemented.
- Local storage is used for the prototype; full backend integration with Firebase will come in later sprints.

---

## Project Management

* Backlog management: Product backlog and Sprint backlog in a [GitHub Projects board](#);
* Release management: v0, v1, v2, v3, ...;
* Sprint planning and retrospectives:
    * **Plans**: screenshots of GitHub Projects board at the beginning and end of each Sprint;
    * **Retrospectives**: meeting notes addressing:
        * ✅ Did well — things we did well and should continue;
        * 🔁 Do differently — things we should change and how;
        * ❓ Puzzles — things we're unsure about;
        * 📌 Improvements to implement next Sprint;

### Sprint 0

_[Add Sprint 0 planning screenshots and retrospective notes here.]_

### Sprint 1

_[Add Sprint 1 planning screenshots and retrospective notes here.]_

### Sprint 2

_[Add Sprint 2 planning screenshots and retrospective notes here.]_

### Sprint 3

_[Add Sprint 3 planning screenshots and retrospective notes here.]_

### Final Release

_[Describe the final release, linking to the release tag and summarising what was delivered.]_