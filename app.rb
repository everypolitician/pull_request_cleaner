require 'bundler/setup'
require 'json'
require 'sinatra/base'
require 'sidekiq'
require 'octokit'
require 'dotenv'
Dotenv.load

Octokit.auto_paginate = true

GITHUB = Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])

class FindOutdatedPullRequests
  class Error < StandardError; end
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def outdated_pull_requests(number)
    pull = pull_requests.find { |p| p[:number] == number.to_i }

    fail Error, "Can't find pull #{number}" if pull.nil?

    # Pull which have the same title, different number and are older are
    # considered outdated.
    pull_requests.find_all do |p|
      p[:title] == pull[:title] &&
        p[:number] != pull[:number] &&
        p[:created_at] <= pull[:created_at] &&
        p[:user][:login] == pull[:user][:login]
    end
  end

  private

  def pull_requests
    @pull_requests ||= GITHUB.pull_requests(repository)
  end
end

class PullRequestCleanerJob
  include Sidekiq::Worker

  def perform(pull_request_number)
    finder = FindOutdatedPullRequests.new(everypolitician_data_repo)
    outdated = finder.outdated_pull_requests(pull_request_number)
    message = "This Pull Request has been superseded by ##{pull_request_number}"
    outdated.each do |pull|
      GITHUB.add_comment(everypolitician_data_repo, pull_request_number, message)
      GITHUB.close_pull_request(everypolitician_data_repo, pull_request_number)
    end
  end

  def everypolitician_data_repo
    ENV.fetch('EVERYPOLITICIAN_DATA_REPO', 'everypolitician/everypolitician-data')
  end
end

class PullRequestCleaner < Sinatra::Base
  get '/' do
    'Send a POST request to this url to trigger the webhook'
  end

  post '/' do
    return "Unhandled event" unless request.env['HTTP_X_EVERYPOLITICIAN_EVENT'] == 'pull_request_opened'
    request.body.rewind
    payload = JSON.parse(request.body.read)
    pull_request_number = payload['pull_request_url'].split('/').last.to_i
    PullRequestCleanerJob.perform_async(pull_request_number)
  end
end
