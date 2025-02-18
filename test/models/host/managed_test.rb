# frozen_string_literal: true

require 'test_plugin_helper'

class ManagedHostTest < ActiveSupport::TestCase
  let(:os) { FactoryBot.build(:operatingsystem, name: 'Redhat', major: 7, password_hash: 'SHA256').becomes(Redhat) }

  context 'with Passwordstate link' do
    let(:pwsrv) { FactoryBot.build :passwordstate_server, id: 1 }
    let(:facet) { FactoryBot.build :passwordstate_host_facet, passwordstate_server: pwsrv }

    let(:host) { FactoryBot.build :host, :managed, hostname: 'test', operatingsystem: os, passwordstate_facet: facet }

    test 'it uses a placeholder during creation' do
      assert_equal 'PlaceholderDuringCreation', host.root_pass
    end

    test 'it queries Passwordstate for root password' do
      host.stubs(:persisted?).returns true
      host.stubs(:domain).returns mock('Domain') # only checks for existence

      password = mock('Passwordstate::Password')
      password.stubs(:password_id).returns 5
      password.stubs(:password).returns 'ExamplePassword'

      host.expects(:password_entry).with('root', create: true).returns password

      assert_equal '$5$b3jfHuNnvG3KP0Li$tC30snobVKIv059KdooVLHRV0xM/VMTzB9dtaQlRBn8', host.root_pass
    end

    test 'it handles persistent errors "gracefully"' do
      host.stubs(:persisted?).returns true
      host.stubs(:domain).returns mock('Domain') # only checks for existence

      host.expects(:host_pass).with('root', password_hash: 'SHA256').raises EOFError

      assert_equal '625e010ab4e760a08dd6ed8418c91fa6532ef157ef5c15186deec7cc6f26711a', host.root_pass
    end

    context 'when list is changed' do
      let(:pwsrv) { FactoryBot.build :passwordstate_server, api_type: 'api', user: '500' }

      test 'it correctly checks validity' do
        pwsrv.stubs(:api_type).returns('winapi')
        pwlist_mock = Object.new
        pwlist_mock.stubs(:get).raises(Passwordstate::UnauthorizedError.new(401, nil, nil))
        pwsrv.stubs(:password_lists).returns(pwlist_mock)

        refute host.save

        refute_equal 500, facet.password_list_id
      end

      test 'it correctly handles partial updates for non-winapi' do
        pwlist_mock = Object.new
        pwlist_mock.stubs(:get).returns(Object.new)
        pwsrv.stubs(:password_lists).returns(pwlist_mock)

        host.save

        assert_equal 500, facet.password_list_id
      end
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
