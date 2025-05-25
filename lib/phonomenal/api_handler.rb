module Phonomenal
  class ApiHandler
    attr_reader :client, :path, :allowed_methods, :singular

    def initialize(client:, path:, allowed_methods:, singular:)
      @client = client
      @path = path
      @allowed_methods = Set.new(allowed_methods)
      @singular = singular

      prepare_methods!
    end

    def url_for(partial_path)
      "/api/v1/#{partial_path}"
    end

    def prepare_response(http_response)
      Phonomenal::Response.new(http_response)
    end

    def prepare_methods! # rubocop:disable Metrics/AbcSize
      if allowed_methods.include?(:index)
        def self.list
          prepare_response client.get(url_for(path))
        end
      end

      if allowed_methods.include?(:create)
        def self.create(body)
          prepare_response client.post(url_for(path), body: body.to_json)
        end
      end

      if allowed_methods.include?(:update)
        def self.update(id, body)
          prepare_response client.patch(url_for("#{path}/#{id}"), body: body.to_json)
        end
      end

      if allowed_methods.include?(:destroy)
        def self.destroy(id, body)
          prepare_response client.delete(url_for("#{path}/#{id}"), body: body.to_json)
        end
      end

      if allowed_methods.include?(:activate)
        def self.destroy(id)
          prepare_response client.post(url_for("#{path}/#{id}/activate"))
        end
      end

      if allowed_methods.include?(:deactivate)
        def self.deactivate(id)
          prepare_response client.post(url_for("#{path}/#{id}/deactivate"))
        end
      end

      return unless allowed_methods.include?(:show)

      def self.show(id)
        prepare_response client.get(url_for("#{path}/#{id}"))
      end
    end
  end
end
