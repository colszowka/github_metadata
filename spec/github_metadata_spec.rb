# encoding: utf-8
require 'spec_helper'
describe GithubMetadata do
  context "initialized with aslakhellesoy/cucumber" do
    before(:all) do
      @metadata = GithubMetadata.new('aslakhellesoy', 'cucumber')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    describe '#user' do
      specify do
        subject.user.should == 'aslakhellesoy'
      end
    end
    
    describe '#repo' do
      specify do
        subject.repo.should == 'cucumber'
      end
    end
    
    specify do
      subject.should have_wiki
    end
    
    describe '#wiki_pages' do
      specify do
        expected = @raw.match(/Wiki \((\d+)\)/)[1].to_i
        expected.should be > 50
        subject.wiki_pages.should == expected
      end
    end
    
    specify do
      subject.should_not have_issues
    end
    
    describe '#issues' do
      specify do
        subject.issues.should == nil
      end
    end
    
    describe '#pull_requests' do
      specify do
        expected = @raw.match(/Pull Requests \((\d+)\)/)[1].to_i
        subject.pull_requests.should == expected
      end
    end
    
    describe '#contributors' do
      specify do
        expected = @raw.match(/(\d+) contributors/)[1].to_i
        subject.contributors.length.should == expected
      end
    end
    
    describe '#contributor_usernames' do
      specify do
        subject.contributor_usernames.should include('aslakhellesoy')
      end
    end
    
    describe '#contributor_realnames' do
      specify do
        subject.contributor_realnames.should include('Iain Hecker', 'Elliot Crosby-McCullough', 'Aslak Hellesøy')
      end
      
      specify do
        subject.contributor_realnames.length.should < subject.contributor_usernames.length
      end
    end
    
    describe '#contributor_names' do
      specify do
        subject.contributor_names.count.should == subject.contributors.count
      end
      
      specify do
        subject.contributor_names.should include('Iain Hecker', 'Elliot Crosby-McCullough', 'Aslak Hellesøy')
      end
      
      specify do
        subject.contributor_names.should include('marocchino')
      end
    end
  end
  
  context "initialized with colszowka/simplecov" do
    before(:all) do
      @metadata = GithubMetadata.new('colszowka', 'simplecov')
      @raw = open("https://github.com/#{@metadata.user}/#{@metadata.repo}/contributors").read
    end
    subject { @metadata }

    describe '#user' do
      specify do
        subject.user.should == 'colszowka'
      end
    end
    
    describe '#repo' do
      specify do
        subject.repo.should == 'simplecov'
      end
    end

    specify do
      subject.should_not have_wiki
    end
    
    describe '#wiki_pages' do
      specify do
        subject.wiki_pages.should be nil
      end
    end
    
    specify do
      subject.should have_issues
    end

    describe '#issues' do
      specify do
        expected = @raw.match(/Issues \((\d+)\)/)[1].to_i
        subject.issues.should == expected
      end
    end
    
    describe '#pull_requests' do
      specify do
        subject.pull_requests.should be 0
      end
    end
    
    describe '#contributors' do
      specify do
        expected = @raw.match(/(\d+) contributors/)[1].to_i
        subject.contributors.length.should be expected
      end
      
      it 'should be all instance of Contributor' do
        subject.contributors.should be_all {|c| c.instance_of?(GithubMetadata::Contributor)}
      end
    end
    
    describe '#contributor_usernames' do
      specify do
        subject.contributor_usernames.should include('colszowka')
      end
    end
    
    describe '#contributor_realnames' do
      specify do
        subject.contributor_realnames.should include('Christoph Olszowka')
      end
    end
    
    describe '#contributor_names' do
      specify do
        subject.contributor_names.count.should be subject.contributors.count
      end
      specify do
        subject.contributor_names.should include('Christoph Olszowka')
      end
    end
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
      GithubMetadata.fetch('colszowka', 'anotherfunkyrepo').should be nil
    end
  end

end
