#!/usr/bin/env ruby
require_relative 'lib/fiidhub'
require 'logger'

logger = Logger.new('fiidhub.log')

fiidhub = Fiidhub.new
unless fiidhub.rss_updated_items.empty?
  fiidhub.rss_updated_items.each do |updated_item|
    rss_item = Fiidhub::RssItem.new(updated_item)
    logger.info("New article: #{rss_item.title}")
  end

  logger.info("Update RSS feeds snapshot.")
  #fiidhub.update_rss_snapshot
end
