require 'open-uri'
require 'rss'
require 'octokit'
require 'yaml'
require 'nokogiri'
require 'erubis'
require 'time'
require 'logger'
require 'pp'
require 'pry'

# Read configuration from config.yml
module Utility
  def config
    YAML.load_file("#{File.dirname(__FILE__)}/../config/config.yml")
  end

  def logger
    Logger.new("#{File.dirname(__FILE__)}/../fiidhub.log")
  end
end

class Fiidhub
  # RSS feeds
  class Rss
    include Utility
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
      logger.info('Update RSS feeds snapshot.')
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
    include Utility
    attr_accessor :pubDate, :title, :link, :description, :normalized_title

    def initialize(args)
      args.each do |k, v|
        instance_variable_set("@#{k}", v) unless v.nil?
      end
      @repo = config['github']['repo']
      @labels = config['github']['labels']
      Octokit.access_token = config['github']['access_token']
      normalized_title
      prepare_labels
    end

    def git_file_content
      @datetime = @pubDate.iso8601
      template = File.read("#{File.dirname(__FILE__)}/../templates/post.erb")
      erb = Erubis::Eruby.new(template)
      erb.result(binding)
    end

    def git_file_path
      "#{config['fiidhub']['filename_path_prefix']}#{@pubDate.strftime('%Y-%m-%d')}-#{@normalized_title}#{config['fiidhub']['filename_path_postfix']}"
    end

    def normalized_title
      encode_options = {
        invalid: :replace,
        undef: :replace,
        replace: ''
      }
      @normalized_title = @title.encode(Encoding.find('ASCII'), encode_options)
                                .gsub(/\s+/, '-')
                                .downcase
      logger.info("Normalized title: '#{@normalized_title}'.")
      @normalized_title
    end

    def branch_name
      "news/#{@pubDate.strftime('%Y%m%d')}-#{@normalized_title}"
    end

    def branch_ref
      "heads/news/#{@pubDate.strftime('%Y%m%d')}-#{@normalized_title}"
    end

    def create_git_branch
      delete_git_branch if Octokit.refs(@repo, 'heads').find { |head| head[:ref].include?(branch_ref) }
      from_master_sha = Octokit.ref(@repo, 'heads/master')[:object][:sha]
      Octokit.create_ref(@repo, branch_ref, from_master_sha)
      logger.info("Create branch ref. #{branch_ref}")
    end

    def create_git_file
      if Octokit.contents(@repo, ref: branch_ref, path: config['fiidhub']['filename_path_prefix']).find { |c| c[:path].include?(git_file_path) }
        logger.info("Repo already has '#{git_file_path}', skip.")
      else
        Octokit.create_content(
          @repo,
          git_file_path,
          "Add news article that to be translated: '#{@title}'.",
          git_file_content,
          branch: branch_name
        )
        logger.info("Create file '#{git_file_path}'.")
      end
    end

    def delete_git_branch
      Octokit.delete_ref(@repo, branch_ref)
    end

    def prepare_labels
      existed_labels = Octokit.labels(@repo)
      @labels.each do |label|
        unless existed_labels.find { |existed_label| existed_label[:name] == label }
          Octokit.add_label(@repo, label)
        end
      end
    end

    def pull_request_content
      template = File.read("#{File.dirname(__FILE__)}/../templates/pull_request.erb")
      erb = Erubis::Eruby.new(template)
      erb.result(binding)
    end

    def create_pull_request
      create_git_branch
      create_git_file
      pull_request = Octokit.create_pull_request(@repo, 'master', branch_name, "WIP: Translate '#{@title}'", pull_request_content)
      Octokit.add_labels_to_an_issue(@repo, pull_request[:number], @labels)
      logger.info("Create pull request ##{pull_request[:number]}")
    end
  end
end
