require 'test_helper'

class FindOutdatedPullRequestsTest < Minitest::Test
  def test_it_finds_outdated_pull_requests
    VCR.use_cassette('find_outdated_pull_requests') do
      pull_finder = FindOutdatedPullRequests.new('everypolitician/everypolitician-data')
      outdated = pull_finder.outdated_pull_requests(2873)
      assert_equal 6, outdated.size
      assert_equal [2834, 2825, 2785, 2727, 2712, 2668], outdated.map(&:number)
    end
  end

  def test_it_finds_nothing_for_old_pull_requests
    VCR.use_cassette('find_outdated_pull_requests') do
      pull_finder = FindOutdatedPullRequests.new('everypolitician/everypolitician-data')
      outdated = pull_finder.outdated_pull_requests(2668)
      assert_equal 0, outdated.size
    end
  end
end
