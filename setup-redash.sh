#!/usr/bin/env bash
# This script setups dockerized Redash on Ubuntu 18.04.
set -eu

REDASH_BASE_PATH=/opt/redash

create_directories() {
    if [ ! -e $REDASH_BASE_PATH ]; then
        sudo mkdir -p $REDASH_BASE_PATH
        sudo chown $USER:$USER $REDASH_BASE_PATH
    fi

    if [ ! -e $REDASH_BASE_PATH/postgres-data ]; then
        mkdir $REDASH_BASE_PATH/postgres-data
    fi
}

create_config() {
    if [ -e $REDASH_BASE_PATH/env ]; then
        rm $REDASH_BASE_PATH/env
        touch $REDASH_BASE_PATH/env
    fi

    COOKIE_SECRET=$(pwgen -1s 32)
    SECRET_KEY=$(pwgen -1s 32)
    POSTGRES_PASSWORD=$(pwgen -1s 32)
    REDASH_DATABASE_URL="postgresql://postgres:${POSTGRES_PASSWORD}@postgres/postgres"

    echo "PYTHONUNBUFFERED=0" >> $REDASH_BASE_PATH/env
    echo "REDASH_LOG_LEVEL=INFO" >> $REDASH_BASE_PATH/env
    echo "REDASH_REDIS_URL=redis://redis:6379/0" >> $REDASH_BASE_PATH/env
    echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> $REDASH_BASE_PATH/env
    echo "REDASH_COOKIE_SECRET=$COOKIE_SECRET" >> $REDASH_BASE_PATH/env
    echo "REDASH_SECRET_KEY=$SECRET_KEY" >> $REDASH_BASE_PATH/env
    echo "REDASH_DATABASE_URL=$REDASH_DATABASE_URL" >> $REDASH_BASE_PATH/env
}

copy_nginx_config() {
	if [ -e $REDASH_BASE_PATH/nginx/nginx.conf ]; then
        rm -r $REDASH_BASE_PATH/nginx/nginx.conf
    fi
	mv data/nginx.conf $REDASH_BASE_PATH/nginx/
}

setup_compose() {

	if [ -e $REDASH_BASE_PATH/docker-compose.yml ]; then
        rm -r $REDASH_BASE_PATH/docker-compose.yml
    fi
	mv docker-compose.yml $REDASH_BASE_PATH/
	
    cd $REDASH_BASE_PATH

    echo "export COMPOSE_PROJECT_NAME=redash" >> ~/.profile
    echo "export COMPOSE_FILE=/opt/redash/docker-compose.yml" >> ~/.profile
    export COMPOSE_PROJECT_NAME=redash
    export COMPOSE_FILE=/opt/redash/docker-compose.yml
    sudo docker-compose run --rm server create_db
    sudo docker-compose up -d
}

create_directories
create_config
copy_nginx_config
setup_compose
