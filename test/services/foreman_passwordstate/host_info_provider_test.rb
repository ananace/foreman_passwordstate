# frozen_string_literal: true

require 'test_plugin_helper'

class ForemanPasswordstate::HostInfoProviderTest < ActiveSupport::TestCase
  subject { ForemanPasswordstate::HostInfoProvider.new(host).host_info }

  let(:os) { FactoryBot.build(:operatingsystem, name: 'Redhat', major: 7, password_hash: 'SHA256').becomes(Redhat) }
  let(:host) { FactoryBot.build :host, :managed, :with_passwordstate_facet, hostname: 'test', operatingsystem: os }

  context 'with Passwordstate configuration' do
    test 'it generates reasonable passwordstate info' do
      assert host.passwordstate_facet

      pwlist = ::Passwordstate::Resources::PasswordList.new(password_list_id: 5, password_list: 'Test', tree_path: '\\Passwords' 
      get_pwlist = stub_request(:get, 'https://passwordstate.localhost.localdomain/winapi/passwordlists/5')
      host.passwordstate_facet.stubs(:password_list).returns(pwlist)
      host.stubs(:host_pass) # Avoid server availability testing

      refute_requested get_pwlist
      refute_empty subject

      assert_equal(
        {
          'server' => 'Passwordstate test',
          'server_url' => 'https://passwordstate.localhost.localdomain',
          'list' => 'Test',
          'list_path' => '\\Passwords\\Test'
        },
        subject.dig('parameters', 'passwordstate')
      )
    end

    test 'it handles errors gracefully' do
      host.stubs(:host_pass).throws(StandardError)

      assert_empty subject
    end
  end

  context 'without Passwordstate configuration' do
    let(:host) { FactoryBot.build :host, :managed, hostname: 'test', operatingsystem: os }

    test 'it does not generate any passwordstate info' do
      refute host.passwordstate_facet
      assert_empty subject
    end
  end
end
