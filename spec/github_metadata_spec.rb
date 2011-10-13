# encoding: utf-8
require 'spec_helper'
describe GithubMetadata do
  context "initialized with cucumber/cucumber" do
    before(:all) do
      @metadata = GithubMetadata.new('cucumber', 'cucumber')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    its(:user) { should == 'cucumber' }
    its(:repo) { should == 'cucumber' }
  
    specify { should have_wiki }
    its(:wiki_pages) { should == @raw.match(/Wiki[^\d]+(\d+)/)[1].to_i}
    
    # specify { should_not have_issues }
    # its(:issues) { should be_nil }
    it { should have_issues }
    its(:issues) { should == @raw.match(/Issues[^\d]+(\d+)/)[1].to_i }
    
    its(:pull_requests) { should == @raw.match(/Pull Requests[^\d]+(\d+)/)[1].to_i }
    
    its("contributors.length") { should == @raw.match(/(\d+) contributors/)[1].to_i}
    its(:contributor_usernames) { should include('aslakhellesoy') }
    its(:contributor_realnames) { should include('Iain Hecker', 'Elliot Crosby-McCullough', 'David Chelimsky') }
    its("contributor_realnames.length") { should < @metadata.contributor_usernames.length } 
    
    its("contributor_names.length") { should == @metadata.contributors.count }
    its(:contributor_names) { should include('Iain Hecker', 'Elliot Crosby-McCullough', 'David Chelimsky') }
    its(:contributor_names) { should include('marocchino') }
      
    its(:default_branch) { should == 'master' }
    
    its(:commits_feed_url) { should == 'https://github.com/cucumber/cucumber/commits/master.atom' }
  end
  
  context "initialized with colszowka/simplecov" do
    before(:all) do
      @metadata = GithubMetadata.new('colszowka', 'simplecov')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
      @feed = Nokogiri::XML(open(@metadata.commits_feed_url))
    end
    subject { @metadata }

    its(:user) { should == 'colszowka' }
    its(:repo) { should == 'simplecov' }
    
    it { should_not have_wiki }
    its(:wiki_pages) { should be_nil }

    it { should have_issues }
    its(:issues) { should == @raw.match(/Issues[^\d]+(\d+)/)[1].to_i }
    
    its(:pull_requests) { should == @raw.match(/Pull Requests[^\d]+(\d+)/)[1].to_i }
    
    its("contributors.length") { should == @raw.match(/(\d+) contributors/)[1].to_i}
    its(:contributors) { should be_all {|c| c.instance_of?(GithubMetadata::Contributor)} }
    
    its(:contributor_usernames) { should include('colszowka') }
    its(:contributor_realnames) { should include('Christoph Olszowka') }
    its("contributor_names.count") { should == @metadata.contributors.count }
    its(:contributor_names) { should include('Christoph Olszowka') }
    
    its(:default_branch) { should == 'master' }
    
    its(:commits_feed_url) { should == 'https://github.com/colszowka/simplecov/commits/master.atom' }
    
    context "recent_commits" do
      before(:all) do
        @metadata.recent_commits
      end
      subject { @metadata.recent_commits }

      it { should have(20).items }
      
      context ".first" do
        subject { @metadata.recent_commits.first }
        
        it { should be_a(GithubMetadata::Commit)}
        its(:title) { should == @feed.css('entry').first.children.css('title').first.content }
        its(:author) { should == @feed.css('entry').first.children.css('author name').first.content }
        its(:url) { should == @feed.css('entry').first.children.css('link').first['href'] }
        its("committed_at.utc") { should == Time.parse(@feed.css('entry').first.children.css('updated').first.content).utc }
      end
    end
    
    it("should return last commit date for average_recent_committed_at(1)") do 
      subject.average_recent_committed_at(1).should == Time.parse(@feed.css('entry').first.children.css('updated').first.content).utc
    end
    
    its("average_recent_committed_at.to_i") do 
      expected_date = @feed.css('entry updated').map {|u| Time.parse(u.content).to_f}.inject(0){|a,b| a+b} / 20
      should == expected_date.to_i
    end
  end
  
  context "initialized with jquery/jquery" do
    before(:all) do
      @metadata = GithubMetadata.new('jquery', 'jquery')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    specify { should_not have_wiki }
    its(:wiki_pages) { should be_nil }
    
    specify { should_not have_issues }
    its(:issues) { should be_nil }
  end

  context "initialized with an invalid repo path" do
    before(:all) do
      @metadata = GithubMetadata.new('colszowka', 'somefunkyrepo')
    end
    subject { @metadata }
    
    it "should raise GithubMetadata::RepoNotFound when accessing .issues" do
      lambda { subject.issues }.should raise_error(GithubMetadata::RepoNotFound)
    end
    
    it "should raise GithubMetadata::RepoNotFound when accessing .recent_commits" do
      lambda { subject.recent_commits }.should raise_error(GithubMetadata::RepoNotFound)
    end
    
    it "should raise GithubMetadata::RepoNotFound when accessing .average_recent_committed_at" do
      lambda { subject.average_recent_committed_at }.should raise_error(GithubMetadata::RepoNotFound)
    end
  end
  
  describe "fetch with invalid repo path" do
    it "should return nil and swallow the 404" do
      GithubMetadata.fetch('colszowka', 'anotherfunkyrepo').should be_nil
    end
  end
  
  describe "fetch with valid repo path" do
    it "should be a GithubMetadata instance" do
      GithubMetadata.fetch('colszowka', 'simplecov').should be_a(GithubMetadata)
    end
  end

end
