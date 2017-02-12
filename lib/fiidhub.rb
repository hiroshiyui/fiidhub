require 'open-uri'
require 'rss'
require 'octokit'
require 'yaml'
require 'pp'

# Read configuration from config.yml
module Config
  def config
    YAML.load_file("#{File.dirname(__FILE__)}/../config/config.yml")
  end
end

class Fiidhub
  # RSS feeds
  class Rss
    include Config
    def snapshot_path
      "#{File.dirname(__FILE__)}/../#{config['fiidhub']['tmp_path']}/#{config['fiidhub']['rss_snapshot']}"
    end

    def snapshot
      unless File.exist?(snapshot_path)
        File.open(snapshot_path, 'w+') do |file|
          file << open((config['feeds']['url']).to_s).read
        end
      end
      RSS::Parser.parse(File.open(snapshot_path, 'r'))
    end

    def current
      RSS::Parser.parse(open((config['feeds']['url']).to_s))
    end

    def update_snapshot
      File.delete(snapshot_path)
      snapshot
    end

    def snapshot_items
      snapshot.items.map do |item|
        {
          pubDate: item.pubDate,
          title: item.title,
          link: item.link,
          description: item.description
        }
      end
    end

    def current_items
      current.items.map do |item|
        {
          pubDate: item.pubDate,
          title: item.title,
          link: item.link,
          description: item.description
        }
      end
    end

    def updated_items
      current_items - snapshot_items
    end
  end

  # RSS item
  class RssItem
    include Config
    attr_accessor :pubDate, :title, :link, :description
    def initialize(args)
      args.each do |k, v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end
  end
end
