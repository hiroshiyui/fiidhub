install:
	bundle install

install_dev:
	bundle install --with=development

test_xml:
	cp tmp/rss.xml.test tmp/rss.xml
