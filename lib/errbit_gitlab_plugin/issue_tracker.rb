require 'gitlab'
require 'uri'

module ErrbitGitlabPlugin
  class IssueTracker < ErrbitPlugin::IssueTracker
    LABEL = 'gitlab'

    NOTE = "Creating issues may take some time as the actual project ID has to be looked up using the Gitlab API. <br/>
            If you are using gitlab.com as installation, please make sure to use 'https://', otherwise, their API
            will not accept some of the our commands."

    FIELDS = {
        endpoint:            {
            label:       'Gitlab URL',
            placeholder: 'The URL to your gitlab installation or the public gitlab server, e.g. https://www.gitlab.com'
        },
        api_token:           {
            label:       'API Token',
            placeholder: "Your account's API token (see Profile -> Account)"
        },
        path_with_namespace: {
            label:       'Project name',
            placeholder: 'E.g. your_username/your_project'
        },
        labels: {
            label:       'Issue labels (comma separated)',
            placeholder: 'E.g. errbit'
        }
    }

    def self.label
      LABEL
    end

    def self.note
      NOTE
    end

    #
    # Form fields that will be presented to the administrator when setting up
    # or editing the errbit app. The values we collect will be available for use
    # later when we have an instance of this class.
    #
    def self.fields
      FIELDS
    end

    #
    # Icons to be displayed for this issue tracker
    #
    def self.icons
      @icons ||= {
          create:   ['image/png', ErrbitGitlabPlugin.read_static_file('gitlab_create.png')],
          goto:     ['image/png', ErrbitGitlabPlugin.read_static_file('gitlab_goto.png')],
          inactive: ['image/png', ErrbitGitlabPlugin.read_static_file('gitlab_inactive.png')]
      }
    end

    #
    # Used to pass an own template to errbit's issue rendering.
    # The rendered template is then passed to any #create_issue call.
    #
    def render_body_args
      ['errbit_gitlab_plugin/issue', :formats => [:md]]
    end

    #
    # @return [String] the URL to the given project's issues section
    #
    def url
      uri = URI(options[:endpoint])
      format '%s://%s/%s/issues', uri.scheme, uri.host, options[:path_with_namespace]
    end

    def configured?
      self.class.fields.keys.all? { |field_name| options[field_name].present? }
    end

    def comments_allowed?
      true
    end

    # Called to validate user input. Just return a hash of errors if there are any
    def errors
      errs = []

      # Make sure that every field is filled out
      self.class.fields.except(:project_id).each_with_object({}) do |(field_name, field_options), h|
        if options[field_name].blank?
          errs << "#{field_options[:label]} must be present"
        end
      end

      # We can only perform the other tests if the necessary values are at least present
      return {:base => errs.to_sentence} unless errs.size.zero?

      # Check if the given endpoint actually exists
      unless gitlab_endpoint_exists?(options[:endpoint])
        errs << 'No Gitlab installation was found under the given URL'
        return {:base => errs.to_sentence}
      end

      # Check if a user by the given token exists
      unless gitlab_user_exists?(options[:endpoint], options[:api_token])
        errs << 'No user with the given API token was found'
        return {:base => errs.to_sentence}
      end

      # Check if there is a project with the given name on the server
      unless gitlab_project_id(options[:endpoint], options[:api_token], options[:path_with_namespace])
        errs << "A project named '#{options[:path_with_namespace]}' could not be found on the server.
                 Please make sure to enter it exactly as it appears in your address bar in Gitlab (case sensitive)"
        return {:base => errs.to_sentence}
      end

      {}
    end

    def create_issue(title, body, reported_by = nil)
      ticket = with_gitlab do |g|
        g.create_issue(gitlab_project_id, title, description: body, labels: options[:labels])
      end

      format('%s/%s', url, ticket.id)
    end

    private

    #
    # Tries to find a project with the given name in the given Gitlab installation
    # and returns its ID (if any)
    #
    def gitlab_project_id(gitlab_url = options[:endpoint], token = options[:api_token], project = options[:path_with_namespace])
      @project_id ||= with_gitlab(gitlab_url, token) do |g|
        g.projects.auto_paginate.detect { |p| p.path_with_namespace == project }.try(:id)
      end
    end

    #
    # @return [String] a formatted APIv4 URL for the given +gitlab_url+
    #
    def gitlab_endpoint(gitlab_url)
      uri = URI(gitlab_url)
      format '%s://%s/api/v4', uri.scheme, uri.host
    end

    #
    # Checks whether there is a gitlab installation
    # at the given +gitlab_url+
    #
    def gitlab_endpoint_exists?(gitlab_url)
      with_gitlab(gitlab_url, 'Iamsecret') do |g|
        g.user
      end
    rescue Gitlab::Error::Unauthorized
      true
    rescue Exception
      false
    end

    #
    # Checks whether a user with the given +token+ exists
    # in the gitlab installation located at +gitlab_url+
    #
    def gitlab_user_exists?(gitlab_url, private_token)
      with_gitlab(gitlab_url, private_token) do |g|
        g.user
      end

      true
    rescue Gitlab::Error::Unauthorized
      false
    end

    #
    # Connects to the gitlab installation at +gitlab_url+
    # using the given +private_token+ and executes the given block
    #
    def with_gitlab(gitlab_url = options[:endpoint], private_token = options[:api_token])
      yield Gitlab.client(endpoint:      gitlab_endpoint(gitlab_url),
                          private_token: private_token,
                          user_agent:    'Errbit User Agent')
    end
  end
end
