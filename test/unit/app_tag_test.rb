# -*- encoding : utf-8 -*-
require 'test_helper'

class AppTagTest < ActiveSupport::TestCase
  setup do
    @user = users(:alex)
    @app = apps(:swably)
    @tag = tags(:game)
  end

  test "add a tag by name" do
    assert_difference('AppTag.count') do
      AppTag.addOrUpdate @user.id, @app.id, "market" 
    end
  end

  test "add a tag object" do
    assert_difference('AppTag.count') do
      AppTag.addOrUpdate @user.id, @app.id, @tag
    end
  end

end