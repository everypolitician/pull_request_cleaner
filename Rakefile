require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'test'
  t.test_files = FileList['test/*_test.rb']
  t.verbose = true
end

require 'dotenv/tasks'

task app: :dotenv do
  require_relative './app'
end

task cleanup: :app do
  total = 0
  github = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  finder = FindOutdatedPullRequests.new('everypolitician/everypolitician-data')
  pull_requests = github.pull_requests('everypolitician/everypolitician-data')
  grouped_pull_requests = pull_requests.group_by { |pr| pr[:title] }
  grouped_pull_requests.each do |title, pulls|
    next if pulls.size == 1
    outdated = finder.outdated_pull_requests(pulls.first[:number])
    puts "Found #{outdated.size} pull(s) with the same title as #{pulls.first[:number]} (#{title})"
    total += outdated.size
  end
  puts "Found #{total} pull requests that can be closed"
end
