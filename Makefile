TIMESTAMP_TAG = $(shell date '+%Y%m%d%H%M%S')

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
	mkdir -p fiidhub_log &&\
	mkdir -p fiidhub_tmp &&\
	docker run --rm -i -t \
	-u $(USER) \
	-v $(PWD)/fiidhub_tmp:/home/$(USER)/fiidhub/tmp \
	-v $(PWD)/fiidhub_log:/home/$(USER)/fiidhub/log \
	--name fiidhub-runner \
	fiidhub
