
class RelationshipsController < ApplicationController
  before_filter :log_access
  #before_filter :log_online
  
  #api
  def follow
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    if(@current_user.id != params[:id].to_i)
      #notify_follow(@user) if @current_user.follow(@user) 
      @current_user.try_follow(@user)
    end
    api_response @user.facade(@current_user), "user"
  end
  
  #api
  def unfollow
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @current_user.unfollow(@user)
    api_response @user.facade(@current_user), "user"
  end

  #api
  def unrequest
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @current_user.unrequest(@user)
    api_response @user.facade(@current_user), "user"
  end

  def accept
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    if(@current_user.id != params[:id])
      @user.follow(@current_user)
      @user.unrequest(@current_user)
    end
    api_response @user.facade(@current_user), "user"
  end

  #api
  def decline
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @user.unrequest(@current_user)
    @user.unfollow(@current_user)
    api_response @user.facade(@current_user), "user"
  end

  #api
  def remove
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @user.unfollow(@current_user)
    api_response @user.facade(@current_user), "user"
  end

  #api
  def block
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @current_user.block(@user) 
    api_response @user.facade(@current_user), "user"
  end
  
  #api
  def unblock
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    @current_user.unblock(@user) 
    api_response @user.facade(@current_user), "user"
  end

  #api
  def show
    return unless validate_format
    return unless validate_signin
    return unless validate_id_and_get_user
    ret = {}
    ret[:following] = @current_user.is_friend(@user.id) != false
    ret[:followed_by] = @user.is_friend(@current_user.id) != false
    ret[:requesting] = @current_user.is_requesting(@user.id) != false
    ret[:requested_by] = @user.is_requesting(@current_user.id) != false
    ret[:blocking] = @current_user.blocked(@user.id) != false
    ret[:blocked_by] = @user.blocked(@current_user.id) != false
    api_response ret, "relation"
  end

  #api
  def batch_follow
    return unless validate_format
    return unless validate_signin
    ids = params[:ids].split(",").compact
    ids.delete @current_user.id
    ids.each do |id|
      user = User.find_by_id(id)
      @current_user.try_follow(user)
    end
    render :nothing => true
  end

private
end

