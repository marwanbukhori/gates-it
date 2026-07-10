FROM php:8.3-fpm-alpine

RUN apk add --no-cache \
      git \
      unzip \
      libzip-dev \
      icu-dev \
      oniguruma-dev \
      $PHPIZE_DEPS \
    && docker-php-ext-install \
      pdo_mysql \
      bcmath \
      intl \
      zip \
      opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./
RUN composer install --no-dev --no-scripts --no-interaction --prefer-dist --no-progress

COPY . .

RUN composer dump-autoload --optimize \
    && chown -R www-data:www-data storage bootstrap/cache

EXPOSE 9000
CMD ["php-fpm"]
