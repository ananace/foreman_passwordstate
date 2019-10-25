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

  # TODO: Validate User + Password or only APIKey

  scoped_search on: :name
  default_scope -> { order('passwordstate_servers.name') }

  delegate :version, :passwords, to: :client

  def test_connection(options = {})
    return false unless url

    client.valid?
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
          load [get(#{user}, { _force: true })]
        end
        CODE
      end.map(&:attributes)
    end
    client.password_lists.load data.map { |d| client.password_lists.new d }
  end

  def get_list_url(pwlist)
    client.server_url.dup.tap { |u| u.query = "plid=#{pwlist.password_list_id}" }
  end

  private

  def client
    require 'passwordstate'

    @client ||= Passwordstate::Client.new(url, api_type: api_type.to_sym, timeout: 10).tap do |cl|
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
end
