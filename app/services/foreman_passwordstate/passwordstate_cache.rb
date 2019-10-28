# frozen_string_literal: true

module ForemanPasswordstate
  # Trimmed copy of Foreman's ComputeResourceCache
  class PasswordstateCache
    attr_accessor :owner, :cache_duration
    delegate :logger, to: ::Rails

    def initialize(owner, cache_duration: 60.minutes)
      self.owner = owner
      self.cache_duration = cache_duration
    end

    def cache(key, **options, &block)
      cached_value = read(key, **options)
      return cached_value if cached_value
      return unless block_given?

      uncached_value = get_uncached_value(key, &block)
      write(key, uncached_value)

      uncached_value
    end

    def delete(key)
      logger.debug("Deleting #{key} from passwordstate cache")
      Rails.cache.delete(cache_key + key.to_s)
    end

    def read(key, **options)
      logger.debug("Reading #{key} in passwordstate cache")
      Rails.cache.read(cache_key + key.to_s, cache_options.merge(options))
    end

    def write(key, value)
      logger.debug("Writing #{key} in passwordstate cache")
      Rails.cache.write(cache_key + key.to_s, value, cache_options)
    end

    def refresh
      logger.debug('Refreshing passwordstate cache')
      Rails.cache.delete(cache_scope_key)
      true
    rescue StandardError => e
      Foreman::Logging.exception('Failed to refresh a Passwordstate cache', e)
      false
    end

    def cache_scope
      Rails.cache.fetch(cache_scope_key, cache_options) do
        Foreman.uuid
      end
    end

    private

    def get_uncached_value(key, &block)
      return unless block_given?

      start_time = Time.now
      result = owner.instance_eval(&block)
      end_time = Time.now

      duration = end_time - start_time.round(4)
      logger.debug("Loaded passwordstate data for #{key} in #{duration} seconds")

      result
    end

    def cache_key
      "passwordstate_#{owner.id}-#{cache_scope}/"
    end

    def cache_scope_key
      "passwordstate_#{owner.id}-cache_scope_key"
    end

    def cache_options
      {
        :expires_in => cache_duration,
        :race_condition_ttl => 1.minute,
      }
    end
  end
end
