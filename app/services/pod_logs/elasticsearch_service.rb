# frozen_string_literal: true

module PodLogs
  class ElasticsearchService < PodLogs::BaseService
    steps :check_arguments,
          :get_raw_pods,
          :get_pod_names,
          :check_times,
          :check_search,
          :check_cursor,
          :pod_logs,
          :filter_return_keys

    self.reactive_cache_worker_finder = ->(id, _cache_key, namespace, params) { new(::Clusters::Cluster.find(id), namespace, params: params) }

    private

    def valid_params
      super + %w(search start_time end_time cursor)
    end

    def success_return_keys
      super + %i(cursor)
    end

    def check_times(result)
      result[:start_time] = params['start_time'] if params.key?('start_time') && Time.iso8601(params['start_time'])
      result[:end_time] = params['end_time'] if params.key?('end_time') && Time.iso8601(params['end_time'])

      success(result)
    rescue ArgumentError
      error(_('Invalid start or end time format'))
    end

    def check_search(result)
      result[:search] = params['search'] if params.key?('search')

      success(result)
    end

    def check_cursor(result)
      result[:cursor] = params['cursor'] if params.key?('cursor')

      success(result)
    end

    def pod_logs(result)
      client = cluster&.application_elastic_stack&.elasticsearch_client
      return error(_('Unable to connect to Elasticsearch')) unless client

      response = ::Gitlab::Elasticsearch::Logs.new(client).pod_logs(
        namespace,
        pod_name: result[:pod_name],
        container_name: result[:container_name],
        search: result[:search],
        start_time: result[:start_time],
        end_time: result[:end_time],
        cursor: result[:cursor]
      )

      result.merge!(response)

      success(result)
    rescue Elasticsearch::Transport::Transport::ServerError => e
      ::Gitlab::ErrorTracking.track_exception(e)

      error(_('Elasticsearch returned status code: %{status_code}') % {
        # ServerError is the parent class of exceptions named after HTTP status codes, eg: "Elasticsearch::Transport::Transport::Errors::NotFound"
        # there is no method on the exception other than the class name to determine the type of error encountered.
        status_code: e.class.name.split('::').last
      })
    rescue ::Gitlab::Elasticsearch::Logs::InvalidCursor
      error(_('Invalid cursor value provided'))
    end
  end
end
