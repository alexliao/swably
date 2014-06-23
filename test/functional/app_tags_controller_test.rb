# -*- encoding : utf-8 -*-
require 'test_helper'

class AppTagsControllerTest < ActionController::TestCase
  setup do
    @user = users(:alex)
    @app = apps(:swably)
    @tag = tags(:game)
  end

  test "create" do
    post :create, user_id: @user.id, app_id: @app.id, tag_name: "market", format: :json
    assert_response :success
  end

  test "destroy" do
    delete :destroy, user_id: @user.id, app_id: @app.id, tag_name: @tag.name, format: :json
    assert_response :success
  end
end