# encoding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'
require 'feedzirra'

# A simple scraper that fetches data from github repos that is not
# available via the API. See README for an introduction and overview.
class GithubMetadata
  class RepoNotFound < StandardError; end;
  
  attr_reader :user, :repo
  
  # Object representation of a github contributor
  class Contributor
    attr_reader :username, :realname
    def initialize(username, realname=nil)
      @username, @realname = username, realname
    end
  end
  
  # Object representation of a commit, initialized
  # from a github repo commit feed entry
  class Commit
    attr_reader :title, :message, :committed_at, :url, :author
    
    def initialize(atom_entry)
      @atom_entry = atom_entry
      @title = atom_entry.title
      @message = atom_entry.content
      @author = atom_entry.author
      @committed_at = atom_entry.updated.kind_of?(Time) ? atom_entry.updated : Time.parse(atom_entry.updated)
      @url = atom_entry.url
    end
    
    private
      def atom_entry
        @atom_entry
      end
  end
  
  def initialize(user, repo)
    @user, @repo = user, repo
  end
  
  # Similar to initialization with GithubMetadata.new, but it will immediately try
  # to fetch the repo document and importantly will swallow GithubMetadata::RepoNotFound 
  # errors, returning nil instead so you can easily do something like this:
  #
  # if metadata = GithubMetadata.fetch('rails', 'rails')
  #   ...
  # end
  def self.fetch(user, repo)
    instance = new(user, repo)
    instance.issues
    instance
  rescue GithubMetadata::RepoNotFound => err
    nil
  end
  
  def github_url
    "https://github.com/#{user}/#{repo}/"
  end
  
  def contributors_url
    File.join(github_url, 'contributors')
  end
  
  def branches_url
    File.join(github_url, 'branches')
  end
  
  def commits_feed_url
    File.join(github_url, "commits/#{default_branch}.atom")
  end
  
  # Returns an array of GithubMetadata::Contributor instances, one for each
  # contributor listed on the contributors page of github
  def contributors
    load_contributors unless @contributors
    @contributors
  end
  
  # Shorthand form for getting an array of all contributor github usernames
  def contributor_usernames
    @contributor_usernames ||= contributors.map(&:username)
  end
  
  # Shorthand form for getting an array of all contributor github realnames,
  # with users that don't have a realname specified filtered out
  def contributor_realnames
    @contributor_realnames ||= contributors.map(&:realname).compact
  end
  
  # Will return all contributor real names, falling back to the username when 
  # real name is not specified
  def contributor_names
    @contributor_names ||= contributors.map {|c| c.realname || c.username }
  end
  
  # Returns true when the repo has a wiki
  def has_wiki?
    !!wiki_pages
  end
  
  # Returns the amount of wiki pages or nil when no wiki is present
  def wiki_pages
    wiki_link = document.at_css('a[highlight="repo_wiki"] .counter')
    return nil unless wiki_link
    wiki_link.text[/\d+/].to_i
  end
  
  # Returns true if the repo has issues enabled
  def has_issues?
    !!issues
  end
  
  # Returns issue count or nil if issues are disabled
  def issues
    issue_link = document.at_css('a[highlight="issues"] .counter')
    return nil unless issue_link
    issue_link.text[/\d+/].to_i
  end
  
  # Returns amount of pull requests
  def pull_requests
    pull_request_link = document.at_css('a[highlight="repo_pulls"] .counter')
    return nil unless pull_request_link
    pull_request_link.text[/\d+/].to_i
  end
  
  # Returns the default branch of the repo
  def default_branch
    @default_branch ||= Nokogiri::HTML(open(branches_url)).at_css('tr.base td.name h3').text.strip.chomp
  rescue OpenURI::HTTPError => err
    raise GithubMetadata::RepoNotFound, err.to_s
  end
  
  # Returns (at most) the last 20 commits (fetched from atom feed of the default_branch)
  # as instances of GithubMetadata::Commit
  def recent_commits
    @recent_commits ||= commits_feed.entries.map {|e| GithubMetadata::Commit.new(e) }
    
  # TODO: Write tests for this error handling. See commits_feed method - this will result in NoMethodError 'entries' on nil
  rescue NoMethodError => err
    nil
  end
  
  # Returns the average date of recent commits (by default all (max 20), can be modified
  # by giving the optional argument)
  def average_recent_committed_at(num=100)
    commit_times = recent_commits[0...num].map {|c| c.committed_at.to_f }
    return nil if commit_times.empty?
    average_time = commit_times.inject(0) {|s, i| s + i} / commit_times.length
    Time.at(average_time).utc
  end
  
  private
  
    def document
      @document ||= Nokogiri::HTML(open(contributors_url))
    rescue OpenURI::HTTPError => err
      raise GithubMetadata::RepoNotFound, err.to_s
    end
    
    def commits_feed
      return @commits_feed if @commits_feed
      
      http_response = open(commits_feed_url)
      if http_response.status[0].to_i == 200
        # sub \n is required since github decided to make their atom feed invalid by adding a blank line before the xml instruct
        @commits_feed = Feedzirra::Feed.parse(http_response.read.sub("\n", ''))
      else
        nil
      end
    end
    
    def load_contributors
      @contributors = document.css('#repos #watchers.members li').map do |contributor|
        line = contributor.text.gsub("\n", '').squeeze(' ').strip.chomp
        username = line.match(/^([^\ ]+)/)[1]
        
        name_match = line.match(/\(([^\)]+)\)/)
        real_name = name_match ? name_match[1] : nil
        
        GithubMetadata::Contributor.new(username, real_name)
      end
    end
end
