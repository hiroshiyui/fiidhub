#!/usr/bin/env ruby
# encoding: utf-8
# frozen_string_literal: true
require_relative 'lib/fiidhub'

include Utility
logger.info("Starting Fiidhub...")

fiidhub = Fiidhub::Rss.new
unless fiidhub.updated_items.empty?
  fiidhub.updated_items.each do |updated_item|
    item = Fiidhub::RssItem.new(updated_item)
    logger.info("New article: #{item.title}")

    item.create_pull_request
  end

  fiidhub.update_snapshot
end
