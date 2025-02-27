# frozen_string_literal: true

class PasswordstateServer < ApplicationRecord
  include ForemanPasswordstate::PasswordstateCaching
  include Taxonomix
  include Encryptable

  extend FriendlyId
  friendly_id :name
  include Parameterizable::ByIdName
  encrypts :password

  validates_lengths_from_database

  audited except: %i[password]

  before_destroy EnsureNotUsedBy.new :hosts
  has_many :passwordstate_host_facets,
           class_name: '::ForemanPasswordstate::PasswordstateHostFacet',
           dependent: :destroy,
           inverse_of: :passwordstate_server
  has_many :passwordstate_hostgroup_facets,
           class_name: '::ForemanPasswordstate::PasswordstateHostgroupFacet',
           dependent: :destroy,
           inverse_of: :passwordstate_server

  has_many :hosts,
           class_name: '::Host::Managed',
           dependent: :nullify,
           inverse_of: :passwordstate_server,
           through: :passwordstate_host_facets
  has_many :hostgroups,
           class_name: '::Hostgroup',
           dependent: :nullify,
           inverse_of: :passwordstate_server,
           through: :passwordstate_hostgroup_facets

  validates :name, presence: true, uniqueness: true
  validates :url, presence: true
  validates :api_type, presence: true

  validate :validate_api_configuration

  scoped_search on: :name
  default_scope -> { order('passwordstate_servers.name') }

  delegate :version, :passwords, to: :client

  def test_connection(**_)
    return false unless url

    client.valid?
  rescue StandardError
    false
  end

  def folders
    data = cache.cache(:folders) do
      return client.folders.map(&:attributes) if api_type.to_sym == :winapi

      client.folders.tap do |folders|
        folders.instance_eval <<-CODE, __FILE__, __LINE__ + 1
        def lazy_load
          load []
        end
        CODE
      end.map(&:attributes)
    end
    client.folders.load data.map { |d| client.folders.new d }
  end

  def hosts
    data = cache.cache(:hosts) do
      client.hosts.map(&:attributes)
    end
    client.hosts.load data.map { |d| client.hosts.new d }
  end

  def password_lists
    data = cache.cache(:password_lists) do
      return client.password_lists.map(&:attributes) if api_type.to_sym == :winapi

      # Only handle a single password list if using API keys
      client.password_lists.tap do |list|
        list.instance_eval <<-CODE, __FILE__, __LINE__ + 1
        def lazy_load
          load [get(#{user}, _force: true)] # load [get(15, _force: true)]
        rescue StandardError => ex
          client.logger.error "Failed to load entries for password list - \#{ex.class}: \#{ex}"
          load []
        end
        CODE
      end.map(&:attributes)
    end
    client.password_lists.load data.map { |d| client.password_lists.new d }
  end

  def get_list_url(pwlist)
    URI.join client.server_url, "plid=#{pwlist.password_list_id}"
  end

  def get_password_url(password)
    URI.join client.server_url, "pid=#{password.password_id}"
  end

  private

  def client
    require 'passwordstate'

    @client ||= Passwordstate::Client.new(url, api_type: api_type.to_sym, open_timeout: 5, timeout: 10).tap do |cl|
      if api_type.to_sym == :api
        cl.auth_data = { apikey: password }
      else
        domain = nil
        username = user

        if (separator = ['/', '\\', '@'].find { |sep| user.include? sep }) && user.count(separator) == 1
          domain, username = user.split(separator)
          domain, username = username, domain if separator == '@'
        end

        cl.auth_data = { username: username, password: password }
        cl.auth_data[:domain] = domain if domain
      end
    end
  end

  def validate_api_configuration
    errors.add(:api_type, 'must be valid') unless %i[winapi api].include?(api_type.to_sym)

    if api_type.to_sym == :api
      errors.add(:password, 'must provide a valid API Key') unless password.size == 32
      errors.add(:user, 'must be a valid Password List ID') unless user.to_i.to_s == user
    else
      errors.add(:user, 'must provide a username') if user.empty?
      errors.add(:password, 'must provide a password') if password.empty?
    end
  end
end
