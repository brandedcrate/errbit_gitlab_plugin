require 'gitlab'

module ErrbitGitlabPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'gitlab'

    NOTE = ''

    FIELDS = [
      [:account, {
        :label       => "Gitlab URL",
        :placeholder => "e.g. https://example.net"
      }],
      [:api_token, {
        :placeholder => "API Token for your account"
      }],
      [:project_id, {
        :label       => "Ticket Project ID (use Number)",
        :placeholder => "Gitlab Project where issues will be created"
      }],
      [:alt_project_id, {
        :label       => "Project Name (namespace/project)",
        :placeholder => "Gitlab Project where issues will be created"
      }]
    ]

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    def self.fields
      FIELDS
    end

    def self.body_template
      @body_template ||= ERB.new(File.read(
        File.join(
          ErrbitGitlabPlugin.root, 'views', 'gitlab_issues_body.txt.erb'
        )
      ))
    end

    def self.summary_template
      @summary_template ||= ERB.new(File.read(
        File.join(
          ErrbitGitlabPlugin.root, 'views', 'gitlab_issues_summary.txt.erb'
        )
      ))
    end

    def url
      sprintf('%s/%s/issues', params['account'], params['alt_project_id'])
    end

    def configured?
      params['project_id'].present? && params['api_token'].present?
    end

    def comments_allowed?; false; end

    def errors
      errors = []
      if self.class.fields.detect {|f| params[f[0]].blank? }
        errors << [:base, 'You must specify your Gitlab URL, API token, Project ID and Project Name']
      end
      errors
    end

    def create_issue(problem, reported_by = nil)
      Gitlab.configure do |config|
        config.endpoint = sprintf('%s/api/v3', params['account'])
        config.private_token = params['api_token']
        config.user_agent = 'Errbit User Agent'
      end

      title = "[#{ problem.environment }][#{ problem.where }] #{problem.message.to_s.truncate(100)}"
      description_summary = self.class.summary_template.result(binding)
      description_body = self.class.body_template.result(binding)

      ticket = Gitlab.create_issue(params['project_id'], title, {
        :description => description_summary,
        :labels => "errbit"
      })

      Gitlab.create_issue_note(params['project_id'], ticket.id, description_body)

      problem.update_attributes(
        :issue_link => sprintf("%s/%s", url, ticket.id),
        :issue_type => self.class.label
      )
    end
  end
end
