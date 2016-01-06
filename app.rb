require 'bundler/setup'
require 'octokit'
require 'dotenv'
Dotenv.load

Octokit.auto_paginate = true

class FindOutdatedPullRequests
  class Error < StandardError; end
  attr_reader :repository

  def initialize(repository)
    @repository = repository
  end

  def outdated_pull_requests(number)
    pull = pull_requests.find { |p| p[:number] == number }

    fail Error, "Can't find pull #{number}" if pull.nil?

    # Pull which have the same title, different number and are older are
    # considered outdated.
    pull_requests.find_all do |p|
      p[:title] == pull[:title] &&
        p[:number] != pull[:number] &&
        p[:created_at] <= pull[:created_at]
    end
  end

  private

  def pull_requests
    @pull_requests ||= github.pull_requests(repository)
  end

  def github
    @github ||= Octokit::Client.new(access_token: ENV['GITHUB_ACCESS_TOKEN'])
  end
end
