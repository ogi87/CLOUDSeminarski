# Custom WordPress image based on official image
FROM wordpress:6.6.2-php8.2-apache

ARG APP_ENV=production
ARG IMAGE_LABEL=fon-wp

LABEL org.opencontainers.image.title="${IMAGE_LABEL}"
ENV APP_ENV=${APP_ENV}


# Enable useful Apache modules
RUN a2enmod rewrite expires headers

# Optional PHP extensions/tools you might need later (uncomment as needed)
# RUN docker-php-ext-install pdo pdo_mysql

# Custom PHP configuration
COPY php.ini /usr/local/etc/php/conf.d/zzz-custom.ini

# Healthcheck for extra credit
HEALTHCHECK --interval=30s --timeout=5s --retries=5 CMD curl -f http://localhost/ || exit 1
