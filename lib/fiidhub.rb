require 'open-uri'
require 'rss'
require 'octokit'
require 'yaml'
require 'pp'

# Fiidhub
class Fiidhub
  attr_accessor :config
  def initialize
    @config = YAML.load_file("#{File.dirname(__FILE__)}/../config/config.yml")
  end

  def rss_snapshot_path
    "#{File.dirname(__FILE__)}/../#{@config['fiidhub']['tmp_path']}/#{@config['fiidhub']['rss_snapshot']}"
  end

  def rss_snapshot
    unless File.exist?(rss_snapshot_path)
      File.open(rss_snapshot_path, 'w+') do |file|
        file << open("#{@config['feeds']['url']}").read
      end
    end
    RSS::Parser.parse(File.open(rss_snapshot_path, 'r'))
  end

  def rss_current
    RSS::Parser.parse(open("#{@config['feeds']['url']}"))
  end
  alias_method :rss, :rss_current

  def update_rss_snapshot
    File.delete(rss_snapshot_path)
    rss_snapshot
  end

  def rss_snapshot_items
    rss_snapshot.items.map do |item|
    {
      pubDate: item.pubDate,
      title: item.title,
      link: item.link,
      description: item.description
    }
    end
  end

  def rss_current_items
    rss_current.items.map do |item|
    {
      pubDate: item.pubDate,
      title: item.title,
      link: item.link,
      description: item.description
    }
    end
  end

  def rss_updated_items
    rss_current_items - rss_snapshot_items
  end

  class RssItem
    attr_accessor :pubDate, :title, :link, :description
    def initialize(args)
      args.each do |k,v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
    end
  end
end
