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
	docker build --rm -t fiidhub:$(TIMESTAMP_TAG) . && \
	docker tag fiidhub:$(TIMESTAMP_TAG) fiidhub:latest

run_docker:
	docker run --rm -i -t \
	-v $(PWD)/fiidhub_tmp:/fiidhub/tmp \
	-v $(PWD)/fiidhub_log:/fiidhub/log \
	--name fiidhub-runner \
	fiidhub
