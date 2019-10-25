# frozen_string_literal: true

module ForemanPasswordstate
  class PasswordstatePasswordsCache
    include Singleton

    # create a private instance of MemoryStore
    def initialize
      @memory_store = ActiveSupport::Cache::MemoryStore.new
    end

    # this will allow our MemoryCache to be called just like Rails.cache
    # every method passed to it will be passed to our MemoryStore
    def method_missing(method, *args, &block)
      if respond_to_missing?(method)
        @memory_store.send(method, *args, &block)
      else
        super
      end
    end

    def respond_to_missing?(method, *)
      @memory_store.respond_to?(method)
    end
  end
end
