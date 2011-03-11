# encoding: utf-8
require 'spec_helper'
describe GithubMetadata do
  context "initialized with aslakhellesoy/cucumber" do
    before(:all) do
      @metadata = GithubMetadata.new('aslakhellesoy', 'cucumber')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    its(:user) { should == 'aslakhellesoy' }
    its(:repo) { should == 'cucumber' }
  
    specify { should have_wiki }
    its(:wiki_pages) { should == @raw.match(/Wiki \((\d+)\)/)[1].to_i }
    
    specify { should_not have_issues }
    its(:issues) { should be_nil }
    
    its(:pull_requests) { should == @raw.match(/Pull Requests \((\d+)\)/)[1].to_i }
    
    its("contributors.length") { should == @raw.match(/(\d+) contributors/)[1].to_i}
    its(:contributor_usernames) { should include('aslakhellesoy') }
    its(:contributor_realnames) { should include('Iain Hecker', 'Elliot Crosby-McCullough', 'David Chelimsky') }
    its("contributor_realnames.length") { should < @metadata.contributor_usernames.length } 
    
    its("contributor_names.length") { should == @metadata.contributors.count }
    its(:contributor_names) { should include('Iain Hecker', 'Elliot Crosby-McCullough', 'David Chelimsky') }
    its(:contributor_names) { should include('marocchino') }
      
    its(:default_branch) { should == 'master' }
  end
  
  context "initialized with colszowka/simplecov" do
    before(:all) do
      @metadata = GithubMetadata.new('colszowka', 'simplecov')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    its(:user) { should == 'colszowka' }
    its(:repo) { should == 'simplecov' }
    
    it { should_not have_wiki }
    its(:wiki_pages) { should be_nil }

    it { should have_issues }
    its(:issues) { should == @raw.match(/Issues \((\d+)\)/)[1].to_i }
    
    its(:pull_requests) { should == 0 }
    
    its("contributors.length") { should == @raw.match(/(\d+) contributors/)[1].to_i}
    its(:contributors) { should be_all {|c| c.instance_of?(GithubMetadata::Contributor)} }
    
    its(:contributor_usernames) { should include('colszowka') }
    its(:contributor_realnames) { should include('Christoph Olszowka') }
    its("contributor_names.count") { should == @metadata.contributors.count }
    its(:contributor_names) { should include('Christoph Olszowka') }
    
    its(:default_branch) { should == 'master' }
  end

  context "initialized with an invalid repo path" do
    before(:all) do
      @metadata = GithubMetadata.new('colszowka', 'somefunkyrepo')
    end
    subject { @metadata }
    
    it "should raise GithubMetadata::RepoNotFound" do
      lambda { subject.issues }.should raise_error(GithubMetadata::RepoNotFound)
    end
  end
  
  describe "fetch with invalid repo path" do
    it "should return nil and swallow the 404" do
      GithubMetadata.fetch('colszowka', 'anotherfunkyrepo').should be_nil
    end
  end

end
