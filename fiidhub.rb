#!/usr/bin/env ruby
# frozen_string_literal: true
require_relative 'lib/fiidhub'
require 'logger'

logger = Logger.new("#{File.dirname(__FILE__)}/fiidhub.log")

fiidhub = Fiidhub::Rss.new
unless fiidhub.updated_items.empty?
  fiidhub.updated_items.each do |updated_item|
    item = Fiidhub::RssItem.new(updated_item)
    logger.info("New article: #{item.title}")
  end

  logger.info('Update RSS feeds snapshot.')
  fiidhub.update_snapshot
end
