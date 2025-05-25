# frozen_string_literal: true

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

    def prepare_methods! # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
      if allowed_methods.include?(:index)
        singleton_class.define_method(:list) do
          prepare_response client.get(url_for(path))
        end
      end

      if allowed_methods.include?(:create)
        singleton_class.define_method(:create) do |body|
          prepare_response client.post(url_for(path), body: body.to_json)
        end
      end

      if allowed_methods.include?(:update)
        singleton_class.define_method(:update) do |id, body|
          prepare_response client.patch(url_for("#{path}/#{id}"), body: body.to_json)
        end
      end

      if allowed_methods.include?(:destroy)
        singleton_class.define_method(:destroy) do |id|
          prepare_response client.delete(url_for("#{path}/#{id}"), body: body.to_json)
        end
      end

      if allowed_methods.include?(:activate)
        singleton_class.define_method(:activate) do |id|
          prepare_response client.post(url_for("#{path}/#{id}/activate"))
        end
      end

      if allowed_methods.include?(:deactivate)
        singleton_class.define_method(:deactivate) do |id|
          prepare_response client.post(url_for("#{path}/#{id}/deactivate"))
        end
      end

      return unless allowed_methods.include?(:show)

      singleton_class.define_method(:show) do |id|
        prepare_response client.get(url_for("#{path}/#{id}"))
      end
    end
  end
end
