# encoding: utf-8
require 'rubygems'
require 'open-uri'
require 'nokogiri'

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
  
  def initialize(user, repo)
    @user, @repo = user, repo
  end
  
  # Similar to initialization with GithubMetadata.new, but it will immediately try
  # to fetch the repo document and importantly will swallow GithubMetadata::RepoNotFound 
  # errors, returning nil instead so you can easily do something like this:
  #
  # if metdata = GithubMetadata.fetch('rails', 'rails')
  #   ...
  # end
  def self.fetch(user, repo)
    instance = new(user, repo)
    instance.issues
    instance
  rescue GithubMetadata::RepoNotFound => err
    nil
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
    wiki_link = document.at_css('a[highlight="repo_wiki"]')
    return nil unless wiki_link
    wiki_link.text[/\d+/].to_i
  end
  
  # Returns true if the repo has issues enabled
  def has_issues?
    !!issues
  end
  
  # Returns issue count or nil if issues are disabled
  def issues
    issue_link = document.at_css('a[highlight="issues"]')
    return nil unless issue_link
    issue_link.text[/\d+/].to_i
  end
  
  # Returns amount of pull requests
  def pull_requests
    pull_request_link = document.at_css('a[highlight="repo_pulls"]')
    return nil unless pull_request_link
    pull_request_link.text[/\d+/].to_i
  end
  
  def default_branch
    document.at_css('.tabs .contextswitch code').text
  end
  
  private
  
    def document
      @document ||= Nokogiri::HTML(open(contributors_url))
    rescue OpenURI::HTTPError => err
      raise GithubMetadata::RepoNotFound, err.to_s
    end
    
    def contributors_url
      "https://github.com/#{user}/#{repo}/contributors"
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
