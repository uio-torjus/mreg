#!/bin/bash
set -e

MREG_LOCALCONF="mregsite/local_settings.py"
# TODO: Add more env-vars for config
touch "$MREG_LOCALCONF"

# Set debug setting
if ! [ -z "$MREG_DEBUG" ]; then
    echo "DEBUG = True" >> "$MREG_LOCALCONF"
fi

# Set up logging to console
if ! [ -z "$MREG_VERBOSE_LOGGING" ]; then
    cat <<EOF >> "$MREG_LOCALCONF"
DJANGO_LOGGING = {
    "CONSOLE_LOG": True,
    'IGNORED_PATHS': ['/admin', '/static', '/favicon.ico', '/api/token-auth']
}
EOF

fi

# Set database settings
if [ "$MREG_DB" == "pg" ]; then

    if [ -z "$MREG_DB_PG_HOST" ]; then
        echo "MREG_DB_PG_HOST not set, assuming mreg-db"
        MREG_DB_PG_HOST="mreg-db"
    fi

    if [ -z "$MREG_DB_PG_PORT" ]; then
        echo "MREG_DB_PG_PORT not set, assuming 5432"
        MREG_DB_PG_PORT="5432"
    fi

    if [ -z "$MREG_DB_PG_USER" ]; then
        echo "MREG_DB_PG_USER not set, assuming mreg_user"
        MREG_DB_PG_USER="mreg_user"
    fi

    if [ -z "$MREG_DB_PG_PASSWORD" ]; then
        echo "MREG_DB_PG_PASSWORD not set, assuming mreg"
        MREG_DB_PG_PASSWORD="mreg"
    fi

    if [ -z "$MREG_DB_PG_DATABASE" ]; then
        echo "MREG_DB_PG_DATABASE not set, assuming mreg"
        MREG_DB_PG_DATABASE="mreg"
    fi

    # Sleep until database can be reached
    until PGPASSWORD="$MREG_DB_PG_PASSWORD" psql -h "$MREG_DB_PG_HOST" \
          -U "$MREG_DB_PG_USER" -c "\q"; do
        echo "Postgres is unavailable - sleeping"
        sleep 1
    done

    cat <<EOF >> "$MREG_LOCALCONF"
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '$MREG_DB_PG_DATABASE',
        'USER': '$MREG_DB_PG_USER',
        'PASSWORD': '$MREG_DB_PG_PASSWORD',
        'HOST': '$MREG_DB_PG_HOST',
    }
}
EOF
    PGPASSWORD="$MREG_DB_PG_PASSWORD" psql -h "$MREG_DB_PG_HOST" \
    -U "$MREG_DB_PG_USER" \
    template1 << EOF
CREATE EXTENSION citext;
CREATE DATABASE $MREG_DB_PG_DATABASE;
GRANT ALL PRIVILEGES ON DATABASE $MREG_DB_PG_DATABASE to $MREG_DB_PG_USER;
EOF
fi

# Skip database migration?
if [ -z "$MREG_NO_MIGRATE" ]; then 
    echo "Running migrations ..."
    python manage.py migrate
    echo "Migration complete ..."
fi

# Load test-fixtures?
if ! [ -z "$MREG_TEST_FIXTURES" ]; then 
    echo "Loading test fixtures"
    python manage.py loaddata mreg/fixtures/fixtures.json
    echo "Loading test fixtures complete"
fi

# Run tests?
if ! [ -z "$MREG_TEST" ]; then
    echo "Running tests"
    exec python manage.py test $@
fi

echo "Starting mreg"
exec gunicorn \
     -b :8000 \
     --workers=4 \
     mregsite.wsgi:application $@
