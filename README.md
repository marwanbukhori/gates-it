# GATES IT Solution — Full-Stack Developer Assessment

**Marwan Bukhori** · [marwanbukhori.dev@gmail.com](mailto:marwanbukhori.dev@gmail.com) · July 2026

![Adoption Home — desktop screenshot](docs/screenshots/01-list-desktop.png)

The assessment asked me to build two small things: a Laravel discount system and a Flutter pet-adoption screen. I built each one **twice** — once as a direct answer to the marking sheet, and once the way I'd actually ship it in production. This repo contains both, both fully working, both tested.

---

## Who is this repo for?

| If you are… | Read this first |
|-------------|-----------------|
| **HR / recruiter** — you just want to know what's here and whether it's complete | [`docs/what-is-this.md`](docs/what-is-this.md) *(1 page, plain English)* |
| **Technical evaluator** — you want to grade against the rubric quickly | [`docs/evaluator-guide.md`](docs/evaluator-guide.md) *(5-minute path, file-by-file)* |
| **Engineering manager** — you want to see how I think about design | [`docs/architecture.md`](docs/architecture.md) and [`docs/decisions.md`](docs/decisions.md) |
| **Developer running the code** — you want to run it locally | [`01-answers/laravel/README.md`](01-answers/laravel/README.md), [`01-answers/flutter/README.md`](01-answers/flutter/README.md), [`02-showcase/laravel/README.md`](02-showcase/laravel/README.md), [`02-showcase/flutter/README.md`](02-showcase/flutter/README.md) |

---

## What's in the box

```
gates-assessment/
├── 📄 Full Stack Developer Assessment.pdf   ← the original brief
├── 📖 docs/                                 ← extra reading
│   ├── what-is-this.md                      (HR-friendly overview)
│   ├── evaluator-guide.md                   (rubric-mapped review path)
│   ├── architecture.md                      (how the code is organised)
│   └── decisions.md                         (why I made the choices I did)
│
├── 📦 01-answers/                           ← DIRECT ANSWERS
│   ├── laravel/                             7 marks — 6/6 tests passing
│   └── flutter/                             5 marks — 6/6 tests passing
│
└── 📦 02-showcase/                          ← PRODUCTION-GRADE VERSIONS
    ├── laravel/                             28/28 tests, Docker, OpenAPI, CI
    └── flutter/                             12/12 tests, custom theme, adaptive UI
```

---

## Why two folders?

**`01-answers/`** is the honest answer to the marking sheet. Every mark is explicitly mapped to a file. Nothing extra. Easy to grade in five minutes.

**`02-showcase/`** is the same problems, but built the way I'd actually deliver them to a production team — clean architecture, dependency injection, custom exceptions, feature tests, containerization, CI, adaptive UI, animations, accessibility. This is where I show *how* I engineer, not just *whether* I can.

Read the answers first to verify the rubric is met. Skim the showcase to see the depth.

---

## Verified end-to-end

I installed the toolchains locally (PHP 8.5.8, Composer 2.10.2, Flutter 3.44.6 via Homebrew) and ran every test against the actual code. Real output:

```
$ (cd 01-answers/laravel && composer test)
OK (6 tests, 6 assertions)

$ (cd 01-answers/flutter && flutter test)
00:00 +6: All tests passed!

$ (cd 02-showcase/laravel && composer test)
{"tool":"phpunit","result":"passed","tests":28,"passed":28,"assertions":52}

$ (cd 02-showcase/flutter && flutter test)
00:00 +12: All tests passed!
```

Both Laravel endpoints were smoke-tested with `php artisan serve` + `curl` — happy paths return 200 with the correct discounted price, invalid inputs return 400 with an RFC 7807 problem-details response. The Flutter showcase was compiled to web, served, and browser-verified — the screenshot at the top of this file is a real render, not a mockup.

---

## Look and feel

Same code, adaptive to screen size:

| Desktop (grid reflows to 4 columns) | Mobile (single column) |
|-------------------------------------|------------------------|
| ![Desktop](docs/screenshots/01-list-desktop.png) | ![Mobile](docs/screenshots/02-list-mobile.png) |

Both are the same Dart code driven by `LayoutBuilder` — no separate mobile / desktop implementations.

---

## Running everything locally

If you want to try it yourself, each project has a full runbook in its own README. The TL;DR:

```bash
# 01 — direct answers
(cd 01-answers/laravel && composer install && composer test)
(cd 01-answers/flutter && flutter pub get && flutter test)

# 02 — showcase
(cd 02-showcase/laravel && composer install && composer test)
(cd 02-showcase/laravel && php artisan serve)        # http://127.0.0.1:8000/api/v1/discount
(cd 02-showcase/flutter && flutter pub get && flutter test)
(cd 02-showcase/flutter && flutter run -d chrome)    # or -d macos
```

Prerequisites: PHP ≥ 8.2 + Composer, Flutter ≥ 3.22. On macOS: `brew install php composer && brew install --cask flutter`.

---

## Contact

**Marwan Bukhori** · marwanbukhori.dev@gmail.com

Happy to walk through the code together — the decisions doc [`docs/decisions.md`](docs/decisions.md) covers the interesting trade-offs if you'd like to prep questions in advance.
