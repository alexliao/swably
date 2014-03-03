# -*- encoding : utf-8 -*-
require 'test_helper'

class WatchesControllerTest < ActionController::TestCase
  setup do
    @user = users(:alex)
    @comment1 = comments(:comm1)
    @comment2 = comments(:comm2)
    @comment100000 = comments(:comm100000)
  end

  test "add" do
    get :add, id: @comment1.id, user_id: @user.id, current_user_id: 1, format: :json
    assert_response :success
  end

  test "cancel" do
    get :cancel, id: @comment100000.id, user_id: @user.id, current_user_id: 1, format: :json
    assert_response :success
  end
end