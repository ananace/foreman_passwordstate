# frozen_string_literal: true

namespace :foreman_passwordstate do
  desc 'Clean up invalid passwords from managed password lists'
  task :cleanup do
    User.as_anonymous_admin do
      list_ids = ForemanPasswordstate::PasswordstateHostFacet.all.map do |facet|
        [facet.passwordstate_server_id, facet.password_list_id]
      end.uniq

      to_remove = []
      list_ids.each do |server_id, list_id|
        puts "For list #{server_id}/#{list_id}"
        server = PasswordstateServer.find server_id
        list = server.password_lists.get(list_id, _bare: true)

        passwords = list.passwords.search description: ":#{server_id}/foreman", exclude_password: true
        puts "- Contains #{passwords.size} passwords"
        passwords.each do |pw|
          unless pw.description.ends_with? ":#{server_id}/foreman"
            puts "- Password #{pw.title} has invalid Foreman link"
            to_remove << pw
            next
          end

          host_id = pw.description.split.last.split(':').first.to_i
          host = Host.find host_id rescue nil
          unless host && host.passwordstate_facet
            puts "- Password #{pw.title} is for non-existent host ID (#{host_id})"
            to_remove << pw
            next
          end

          facet = host.passwordstate_facet
          if facet.password_list_id.to_i != pw.password_list_id.to_i
            puts "- Password #{pw.title} is not in the correct list (should be in #{facet.password_list_id})"
            to_remove << pw
            next
          end
        end
      end

      puts "Found #{to_remove.size} invalid passwords to clean up"

      to_remove.each(&:delete)
    end
  end
end

# Tests
namespace :test do
  desc 'Test ForemanPasswordstate'
  Rake::TestTask.new(:foreman_passwordstate) do |t|
    test_dir = File.join(__dir__, '../..', 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end

  namespace :foreman_passwordstate do
    task :coverage do
      ENV['COVERAGE'] = '1'

      Rake::Task['test:foreman_passwordstate'].invoke
    end
  end
end

Rake::Task[:test].enhance %w[test:foreman_passwordstate]
