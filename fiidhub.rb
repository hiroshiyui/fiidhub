require_relative 'lib/fiidhub'
require 'pp'
fiidhub = Fiidhub.new
#pp fiidhub.rss_snapshot
# p fiidhub.rss
pp fiidhub.rss_updated_items
