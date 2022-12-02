# frozen_string_literal: true

require 'test_plugin_helper'

class HostTest < ActiveSupport::TestCase
  let(:os) { FactoryBot.build(:operatingsystem, name: 'Redhat', major: 7).becomes(Redhat) }

  context 'with Passwordstate link' do
    let(:pwsrv) { PasswordstateServer.new id: 1 }
    let(:facet) { ForemanPasswordstate::PasswordstateHostFacet.new passwordstate_server: pwsrv, password_list_id: 5 }

    let(:host) { FactoryBot.build :host, :managed, hostname: 'test', operatingsystem: os, passwordstate_facet: facet }

    test 'it uses a placeholder during creation' do
      assert_equal 'PlaceholderDuringCreation', host.root_pass
    end

    test 'it queries Passwordstate for root password' do
      host.stubs(:persisted?).returns true
      host.stubs(:domain).returns mock('Domain') # only checks for existence

      password = mock('Passwordstate::Password')
      password.stubs(:password_id).returns 5
      password.expects(:password).returns 'ExamplePassword'

      host.expects(:password_entry).with('root', create: true).returns password

      assert_equal '$5$GOaEWuCfsHMPpxca$UKV.6AnLVIlOw4szcCokGkB6yzXBV26/iWFCCo5yf19', host.root_pass
    end

    test 'it handles persistent errors "gracefully"' do
      host.stubs(:persisted?).returns true
      host.stubs(:domain).returns mock('Domain') # only checks for existence

      host.expects(:host_pass).with('root', password_hash: 'SHA256').raises EOFError

      assert_equal '625e010ab4e760a08dd6ed8418c91fa6532ef157ef5c15186deec7cc6f26711a', host.root_pass
    end
  end

  context 'without Passwordstate link' do
    let(:host) { FactoryBot.build :host, :managed, operatingsystem: os }

    test 'it does not query Passwordstate for the root password' do
      host.expects(:host_pass).never

      assert host.root_pass
    end
  end
end
