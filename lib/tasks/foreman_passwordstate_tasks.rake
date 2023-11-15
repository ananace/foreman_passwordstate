# frozen_string_literal: true

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
