require 'errbit_gitlab_plugin/version'
require 'errbit_gitlab_plugin/issue_tracker'
require 'errbit_gitlab_plugin/rails'

module ErrbitGitlabPlugin
  def self.root
    File.expand_path '../..', __FILE__
  end
end

ErrbitPlugin::Registry.add_issue_tracker(ErrbitGitlabPlugin::IssueTracker)
