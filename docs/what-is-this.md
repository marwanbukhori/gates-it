# What is this? *(one-pager for anyone reading)*

## The short version

GATES IT Solution sent me a coding assessment. It has two parts:

1. **Laravel** — build a discount system for an e-commerce app (fixed / percentage / loyalty discounts)
2. **Flutter** — build a mobile screen that lists adoptable pets and lets you filter and mark them as adopted

This repository contains my answer, delivered as **two folders**:

- **`01-answers/`** — a straightforward answer to the marking sheet
- **`02-showcase/`** — the same problems built to production quality, to show how I actually engineer software

Everything runs. Everything is tested. I ran it locally before sending it.

## What each mark is worth

The Laravel part is out of **7 marks**. The Flutter part is out of **5 marks**. I hit every mark in both folders.

Each project has a table in its own README (a "rubric map") that links every marking-sheet item to the exact file that fulfils it. If you're grading, that table is where to start.

## What the "showcase" folder adds beyond the marking sheet

The marking sheet asks for the classes to exist. The showcase folder shows what I do *after* the classes exist:

**On the Laravel side:**
- A clean separation between business logic and framework code
- A proper API endpoint (`POST /api/v1/discount`) with structured error responses
- A test suite that covers not just the classes but the full HTTP flow (28 tests)
- Docker Compose for reproducible local dev
- An OpenAPI 3.1 specification and a Postman collection for consumers of the API
- A GitHub Actions workflow that runs the tests on every push

**On the Flutter side:**
- A "feature-first" folder structure that scales as the app grows
- Riverpod for state management (industry-standard for medium-to-large Flutter apps)
- A custom Material 3 theme with hand-picked colors and typography, not the default
- A layout that reflows from one column on a phone to four columns on a desktop — same code
- Loading skeletons, empty states, animated transitions when a pet is adopted
- Accessibility labels so screen readers describe the content correctly
- 12 tests covering models, state logic, and the UI

## Time and effort

I built this end-to-end in a single working session. Everything was written by me, then verified by running the actual test suites and taking real screenshots of the live app.

## What I want you to notice

If you're technical, the two folders side-by-side tell you what I care about:

- **`01-answers/laravel/app/Services/DiscountService.php`** works.
- **`02-showcase/laravel/app/Domain/Discount/DiscountService.php`** works *and* is easy to extend, easy to test, and easy to hand to another engineer.

The difference between those two files — same problem, same seven marks — is what senior work looks like. That's the version of me I'd bring to your team.

## Contact

**Marwan Bukhori**
[marwanbukhori.dev@gmail.com](mailto:marwanbukhori.dev@gmail.com)
