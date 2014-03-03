# -*- encoding : utf-8 -*-
require 'test_helper'

class WatchTest < ActiveSupport::TestCase
  test "the truth" do
    assert true
  end

  test "cancel a watch" do
  	old = Watch.count
  	Watch.cancel users(:alex), comments(:comm100000)
  	assert_equal old-1, Watch.count
  end

  test "add a watch" do
    assert_difference('Watch.count') do
	  	Watch.add users(:alex), comments(:comm1)
    end
  end

end