# Pawmise API — Railway deploy image (single web process).
# Root directory for the Railway service must be 02-showcase/laravel.
# Laravel 13 / Symfony 8.1 lockfile requires PHP >= 8.4.1.
FROM php:8.4-cli-bookworm

RUN apt-get update && apt-get install -y --no-install-recommends \
        git unzip libzip-dev libonig-dev \
    && docker-php-ext-install pdo pdo_mysql zip \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app
COPY . .

RUN composer install --no-dev --optimize-autoloader --no-interaction --no-progress

# Railway injects $PORT. Migrations + seed are idempotent (safe on every boot).
# `artisan serve` is fine for a low-traffic reviewer demo; swap for FrankenPHP
# or php-fpm+nginx for real production traffic.
# Seed is idempotent and non-fatal — a seed hiccup must never stop the API booting.
CMD php artisan migrate --force \
    && (php artisan db:seed --force || echo "seed skipped") \
    && php artisan serve --host 0.0.0.0 --port "${PORT:-8000}"
