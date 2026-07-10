# GATES IT Solution — Full-Stack Developer Assessment

**Marwan Bukhori** · [marwanbukhori.dev@gmail.com](mailto:marwanbukhori.dev@gmail.com)

![Pawmise — desktop](docs/screenshots/01-list-desktop.png)

The brief asked for two things: a Laravel discount system and a Flutter pet-adoption screen. I did them **twice**, and I want to be upfront about why.

- **`01-answers/`** — the straightforward answer to the marking sheet. Written by hand, **no AI**, exactly as the brief asks. Every rubric item maps to a file, the tests are green, and it grades in about five minutes.

- **`02-showcase/`** — the same two tasks, but this is **how I use AI**. I directed Claude (with the `superpowers` plugin) to grow them into one real product — **Pawmise**, a pet-adoption platform where the discount engine becomes the adoption-fee calculator. I'm not hiding the AI; I'm showing that I can steer it to ship production-grade software.

So: `01-answers` proves I can do it by hand. `02-showcase` proves I can do a lot more, fast, by leading AI. Read the first to check the boxes; look at the second to see how I actually work.

---

## 🔴 Try it live

I deployed `02-showcase` so you don't have to run anything:

| | Link |
|---|---|
| 🌐 **Web app** (Flutter, live data) | **https://marwanbukhori.github.io/gates-it/** |
| ⚙️ **API** (Laravel on Railway) | **https://pawmise-production.up.railway.app/api/v1/pets** |

The web app lists real pets served by the live API. Prefer the command line?

```bash
# Browse pets
curl https://pawmise-production.up.railway.app/api/v1/pets

# Register, then get a fee quote (loyalty/senior/shelter discounts applied)
curl -X POST https://pawmise-production.up.railway.app/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"name":"You","email":"you@example.com","password":"secret1234"}'
# → copy the "token", then:
curl https://pawmise-production.up.railway.app/api/v1/pets/24/fee-quote \
  -H "Authorization: Bearer <token>"
```

---

## Run it locally

```bash
# 01 — the hand-written answers
(cd 01-answers/laravel && composer install && composer test)
(cd 01-answers/flutter && flutter pub get && flutter test)

# 02 — Pawmise (AI-built)
(cd 02-showcase/laravel && composer install && cp .env.example .env && php artisan key:generate)
(cd 02-showcase/laravel && php artisan migrate --seed && php artisan serve)   # API on :8000
(cd 02-showcase/flutter && flutter pub get && flutter run -d chrome)
```

Needs PHP ≥ 8.4 + Composer and Flutter ≥ 3.22 (`brew install php composer && brew install --cask flutter`).

---

## Want more detail?

| You are… | Start here |
|----------|------------|
| HR / recruiter | [`docs/what-is-this.md`](docs/what-is-this.md) — one plain-English page |
| Grading the rubric | [`docs/evaluator-guide.md`](docs/evaluator-guide.md) — file-by-file |
| An engineer | [`docs/architecture.md`](docs/architecture.md) · [`docs/decisions.md`](docs/decisions.md) |
| Curious about the AI process | [`docs/how-02-was-built.md`](docs/how-02-was-built.md) |
| Deploying it | [`02-showcase/DEPLOY.md`](02-showcase/DEPLOY.md) |

---

Happy to walk through any of it — just ask. **Marwan Bukhori** · marwanbukhori.dev@gmail.com
