module ErrbitGitlabPlugin
  def self.root
    Pathname.new File.expand_path('../..', __FILE__)
  end
end

require 'errbit_gitlab_plugin/version'
require 'errbit_gitlab_plugin/issue_tracker'
require 'errbit_gitlab_plugin/rails'

ErrbitPlugin::Registry.add_issue_tracker(ErrbitGitlabPlugin::IssueTracker)
