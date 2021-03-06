TIMESTAMP_TAG = $(shell date '+%Y%m%d%H%M%S')
USER = $(shell id -u -n)

.PHONY: help install install_dev test_xml git_archive build_docker run_docker clean_docker_old_images

help:
	@echo "Fiidhub - Pipe RSS feeds to GitHub pull requests"

install:
	bundle install

install_dev:
	bundle install --with=development

test_xml:
	cp tmp/rss.xml.test tmp/rss.xml

git_archive:
	git archive --format tar -o tmp/fiidhub.tar master

build_docker: git_archive
	docker build --rm --build-arg user=$(USER) --build-arg uid=$(shell id -u) -t fiidhub:$(TIMESTAMP_TAG) . && \
	docker tag fiidhub:$(TIMESTAMP_TAG) fiidhub:latest

run_docker:
	mkdir -p $(PWD)/fiidhub_tmp $(PWD)/fiidhub_log &&\
	docker run --rm \
	-e LANG=C.UTF-8 \
	-u $(USER) \
	-v $(PWD)/fiidhub_tmp:/home/$(USER)/fiidhub/tmp \
	-v $(PWD)/fiidhub_log:/home/$(USER)/fiidhub/log \
	--name fiidhub-runner \
	fiidhub

clean_docker_old_images:
	docker rmi $(shell docker images -qf before=fiidhub:latest fiidhub)
