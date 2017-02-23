TIMESTAMP_TAG = $(shell date '+%Y%m%d%H%M%S')
USER = $(shell id -u -n)

install: setup_dir
	bundle install

install_dev: setup_dir
	bundle install --with=development

test_xml: setup_dir
	cp tmp/rss.xml.test tmp/rss.xml

git_archive: setup_dir
	git archive --format tar -o tmp/fiidhub.tar master

build_docker: git_archive
	docker build --rm --build-arg user=$(USER) --build-arg uid=$(shell id -u) -t fiidhub:$(TIMESTAMP_TAG) . && \
	docker tag fiidhub:$(TIMESTAMP_TAG) fiidhub:latest

run_docker: setup_dir
	docker run --rm \
	-u $(USER) \
	-v $(PWD)/fiidhub_tmp:/home/$(USER)/fiidhub/tmp \
	-v $(PWD)/fiidhub_log:/home/$(USER)/fiidhub/log \
	--name fiidhub-runner \
	fiidhub

setup_dir:
	mkdir -p log tmp fiidhub_log fiidhub_tmp
