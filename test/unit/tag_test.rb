# -*- encoding : utf-8 -*-
require 'test_helper'

class TagTest < ActiveSupport::TestCase

  test "ensure a new tag" do
    assert_difference('Tag.count') do
      Tag.ensure "tool"
    end
  end

  test "ensure an existing tag" do
    assert_no_difference('Tag.count') do
      Tag.ensure "game"
    end
  end

end