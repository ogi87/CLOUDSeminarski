FROM mariadb:11.4

# Default character set/collation for WP
ENV MARIADB_AUTO_UPGRADE=1

# Healthcheck: ensure DB is accepting connections
HEALTHCHECK --interval=30s --timeout=5s --retries=10 CMD mariadb-admin ping -uroot -p$MARIADB_ROOT_PASSWORD || exit 1
