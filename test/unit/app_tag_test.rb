# -*- encoding : utf-8 -*-
require 'test_helper'

class AppTagTest < ActiveSupport::TestCase
  setup do
    @user = users(:alex)
    @app = apps(:swably)
    @tag_game = tags(:game)
    @tag_market = tags(:market)
  end

  test "add a tag by name" do
    assert_difference('AppTag.count') do
      AppTag.addOrUpdate @user.id, @app.id, "fun" 
    end
  end

  test "add a tag object" do
    assert_difference('AppTag.count') do
      AppTag.addOrUpdate @user.id, @app.id, @tag_market
    end
  end

end