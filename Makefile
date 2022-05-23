# current dir
curdir := `basename $(shell pwd)`
user := $(shell id -nu)
uid := $(shell id -u)
group := $(shell id -ng)
gid := $(shell id -g)

run:
	make git_clean
	make set
	make build  # default Gemfile(rails) install
	make rails_new
	make build  # app Gemfile install
	make db_create
	make up
set:
	sed -i "s/USER=.*/USER=${user}/" .env
	sed -i "s/USER_ID=.*/USER_ID=${uid}/" .env
	sed -i "s/GROUP=.*/GROUP=${group}/" .env
	sed -i "s/GROUP_ID=.*/GROUP_ID=${gid}/" .env
	sed -i "s/APP_NAME=.*/APP_NAME=${curdir}/" .env
rails_new:
	docker-compose run app rails new . --force -d mysql --skip-action-mailbox --skip-active-storage --skip-action-cable -S --skip-spring --skip-system-test --skip-bundle --skip-bootsnap --skip-webpack-install --api
db_create:
	sed -ie "s/host: localhost/host: db/" config/database.yml
	docker-compose run app ruby bin/await_db_connection.rb # db起動待ち
	docker-compose run app rails db:create
git_clean:
	rm -rf .git*
build:
	docker-compose build
up:
	docker-compose up -d
down:
	docker-compose down
mysql:
	docker-compose exec db mysql -u root -p ${curdir}_development
docker_image_clean:
	docker images --format "{{.Repository}}" | grep ${curdir} | xargs docker rmi
docker_stop_all:
	docker ps --format {{.Names}} --filter name=${curdir} | xargs docker stop
docker_prune:
	docker system prune -f
docker_containers:
	docker container ls -a --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
