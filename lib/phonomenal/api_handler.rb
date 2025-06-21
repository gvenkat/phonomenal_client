# frozen_string_literal: true

require "phonomenal/response"

module Phonomenal
  class ApiHandler # rubocop:disable Style/Documentation
    attr_reader :client, :path, :allowed_methods, :singular

    def initialize(client:, path:, allowed_methods:, singular:)
      @client = client
      @path = path
      @allowed_methods = Set.new(allowed_methods)
      @singular = singular

      prepare_methods!
    end

    def url_for(...)
      client.url_for(...)
    end

    def prepare_response(http_response)
      Phonomenal::Response.new(http_response)
    end

    # Just assume all the methods are on members
    def add_method!(method_name:, method: :post)
      singleton_class.define_method(method_name) do |id|
        prepare_response client.class.send(method, url_for("#{path}/#{id}/#{method_name}"))
      end
    end

    def prepare_methods! # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength,Metrics/PerceivedComplexity
      if allowed_methods.include?(:index)
        singleton_class.define_method(:list) do
          prepare_response client.class.get(url_for(path))
        end
      end

      if allowed_methods.include?(:create)
        singleton_class.define_method(:create) do |body|
          prepare_response client.class.post(url_for(path), body: body.to_json)
        end
      end

      if allowed_methods.include?(:update)
        singleton_class.define_method(:update) do |*args|
          body = singular ? args.first : args.last
          url = singular ? path : "#{path}/#{args.first}"

          prepare_response client.class.patch(url_for(url), body: body.to_json)
        end
      end

      if allowed_methods.include?(:destroy)
        singleton_class.define_method(:destroy) do |id|
          prepare_response client.class.delete(url_for("#{path}/#{id}"))
        end
      end

      if allowed_methods.include?(:activate)
        singleton_class.define_method(:activate) do |id|
          prepare_response client.class.post(url_for("#{path}/#{id}/activate"))
        end
      end

      if allowed_methods.include?(:deactivate)
        singleton_class.define_method(:deactivate) do |id|
          prepare_response client.class.post(url_for("#{path}/#{id}/deactivate"))
        end
      end

      return unless allowed_methods.include?(:show)

      singleton_class.define_method(:show) do |*args|
        prepare_response client.class.get(url_for(singular ? path : "#{path}/#{args.first}"))
      end
    end
  end
end
