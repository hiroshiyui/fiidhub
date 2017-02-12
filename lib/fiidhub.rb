require 'open-uri'
require 'rss'
require 'octokit'
require 'yaml'
require 'nokogiri'
require 'erubis'
require 'time'
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
    attr_accessor :pubDate, :title, :link, :description, :branch

    def initialize(args)
      args.each do |k, v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end

      Octokit.access_token = config['github']['access_token']
    end

    def git_file_content
      @datetime = @pubDate.iso8601
      template = File.read("#{File.dirname(__FILE__)}/../templates/item.erb")
      erb = Erubis::Eruby.new(template)
      erb.result(binding())
    end

    def normalized_title
      encode_options = {
        invalid: :replace,
        undef: :replace,
        replace: ''
      }
      @title.encode(Encoding.find('ASCII'), encode_options)
            .gsub(/\s+/, '-')
            .downcase
    end

    def branch_name
      "news/#{@pubDate.strftime('%Y%m%d')}-#{normalized_title}"
    end

    def branch_ref
      "heads/news/#{@pubDate.strftime('%Y%m%d')}-#{normalized_title}"
    end

    def create_git_branch
      # TODO: 可能要處理一下已經存在的同名 branch
      sha = Octokit.ref(config['github']['repo'], "heads/master")[:object][:sha]
      @branch = Octokit.create_ref(config['github']['repo'], branch_ref, sha)
    end

    def create_git_file
      # TODO: 可能也要處理一下撞名的檔案…
      Octokit.create_content(
        config['github']['repo'],
        "_posts/#{@pubDate.strftime('%Y-%m-%d')}-#{normalized_title}-TEST.markdown",
        "Add news article that to be translated: '#{@title}'.",
        git_file_content,
        :branch => branch_name
      )
    end

    def delete_git_branch
      Octokit.delete_ref(config['github']['repo'], branch_ref)
    end
  end
end
