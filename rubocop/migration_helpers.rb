module RuboCop
  # Module containing helper methods for writing migration cops.
  module MigrationHelpers
    WHITELISTED_TABLES = %i[
      application_settings
      plan_limits
    ].freeze

    # Blacklisted table due to:
    #   - size in GB (>= 10 GB on GitLab.com as of 02/2020)
    #   - number of records
    BLACKLISTED_TABLES = %i[
       audit_events
       ci_build_trace_sections
       ci_builds
       ci_builds_metadata
       ci_job_artifacts
       ci_pipeline_variables
       ci_pipelines
       ci_stages
       deployments
       events
       issues
       merge_request_diff_commits
       merge_request_diff_files
       merge_request_diffs
       merge_request_metrics
       merge_requests
       namespaces
       note_diff_files
       notes
       project_authorizations
       projects
       project_ci_cd_settings
       push_event_payloads
       resource_label_events
       routes
       sent_notifications
       services
       system_note_metadata
       taggings
       todos
       users
       web_hook_logs
    ].freeze

    # Returns true if the given node originated from the db/migrate directory.
    def in_migration?(node)
      dirname(node).end_with?('db/migrate', 'db/geo/migrate') || in_post_deployment_migration?(node)
    end

    def in_post_deployment_migration?(node)
      dirname(node).end_with?('db/post_migrate', 'db/geo/post_migrate')
    end

    def version(node)
      File.basename(node.location.expression.source_buffer.name).split('_').first.to_i
    end

    private

    def dirname(node)
      File.dirname(node.location.expression.source_buffer.name)
    end
  end
end
