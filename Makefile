init: docker-down docker-pull docker-build composer-update yarn-install docker-up env key storage passport migrate
up: composer-update docker-up yarn-watch
down: docker-down
restart: down up

HOST = 82.148.19.108
REGISTRY=docker.pkg.github.com/hose1021/devhub

docker-up:
	docker-compose up -d

docker-down:
	docker-compose down --remove-orphans

docker-down-clear:
	docker-compose down -v --remove-orphans

docker-pull:
	docker-compose pull

docker-build:
	DOCKER_BUILDKIT=1 COMPOSE_DOCKER_CLI_BUILD=1 docker-compose build --build-arg BUILDKIT_INLINE_CACHE=1 --pull

optimize:
	docker-compose run --rm php php artisan optimize

composer-install:
	docker-compose run --rm php composer install

composer-update:
	docker-compose run --rm php composer update

yarn-install:
	docker-compose run --rm php yarn install

yarn-upgrade:
	docker-compose run --rm php yarn upgrade

passport:
	docker-compose run --rm php php artisan passport:keys

yarn-watch:
	docker-compose run php yarn watch

env:
	docker-compose run --rm php php -r "file_exists('.env') || copy('.env.example', '.env');"

stop-watch:
	docker stop yarn-watch

storage:
	docker-compose run --rm php php artisan storage:link

key:
	docker-compose run --rm php php artisan key:generate

migrate:
	docker-compose run --rm php php artisan migrate --seed

migrate-fresh:
	docker-compose run --rm php php artisan migrate:fresh --seed

try-build:
	REGISTRY=127.0.0.1 IMAGE_TAG=0 make build

build: build-docker

build-docker:
	DOCKER_BUILDKIT=1 docker --log-level=debug build --pull --build-arg BUILDKIT_INLINE_CACHE=1 \
            --cache-from ${REGISTRY}/devhub:cache \
            --tag ${REGISTRY}/devhub:cache \
            --tag ${REGISTRY}/devhub:${IMAGE_TAG} \
            --file Dockerfile .

push:
	docker-compose push

deploy:
	scp -o StrictHostKeyChecking=no Dockerfile root@${HOST}:site_1/Dockerfile
	scp -o StrictHostKeyChecking=no docker-compose.yml root@${HOST}:site_1/docker-compose.yml
	ssh -o StrictHostKeyChecking=no root@${HOST} 'cd site_1 && env REGISTRY=${REGISTRY}'
	ssh -o StrictHostKeyChecking=no root@${HOST} 'cd site_1 && env IMAGE_TAG=cache'
	ssh -o StrictHostKeyChecking=no root@${HOST} 'cd site_1 && docker-compose pull'
	ssh -o StrictHostKeyChecking=no root@${HOST} 'cd site_1 && docker-compose up --build --remove-orphans -d'
	ssh -o StrictHostKeyChecking=no root@${HOST} 'rm -f site'
	ssh -o StrictHostKeyChecking=no root@${HOST} 'ln -sr site_1 site'
