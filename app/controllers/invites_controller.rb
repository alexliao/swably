class InvitesController < ApplicationController
  before_filter :log_access
  
  def show
#    if params[:id]
#      @invite = Invite.find_by_invite_code(params[:id])
#    elsif params[:request_ids]
#      request_ids = params[:request_ids].split(",")
#      request_ids.each do |id|
#        @invite = Invite.find_by_request_id(id)
#        break if @invite and @invite.invitee_id.nil?
#      end
#    end
#    unless @invite
#      redirect_to "/"
#    end
      redirect_to "/"
  end
  
  #api
  def create
    return unless validate_format
    @invite = Invite.new()
    @invite.invitor_id = @current_user.id unless @current_user.is_anonymous
    @invite.request_id = params[:request_id]
    @invite.invitee_eid = params[:to]
    @invite.invite_code = gen_invite_code
    @invite.save
    api_response @invite.facade, "invite"
  end
  
#  #api
#  def validate
#    return unless validate_format
#    @invite = Invite.find_by_invite_code(params[:id])
#    if @invite
#      if @invite.invitee_id
#        api_error "Invite code [#{params[:id]}] is used by someone else", 403
#      else
#        api_response @invite.facade, "invite"
#      end
#    else
#      api_error "Invite code [#{params[:id]}] is invalid", 404
#    end
#  end

  #api
  def accept
    return unless validate_format
    return unless validate_signin
    @invite = Invite.find_by_invite_code(params[:id])
    if @invite
      if @invite.invitee_id
        api_error "This code is used by someone else", 403
      else
        @current_user.activated = true
        @current_user.save        
        @invite.invitee_id = @current_user.id
        @invite.save
        api_response @invite.facade, "invite"
      end
    else
      api_error "This code is invalid", 404
    end
  end
  
  #api
  def sns
    return unless validate_format
    provider = OAuthProvider.get_instance(params[:id])
    provider.invite(@current_user, params[:eid], params[:content])
    render :nothing => true
  end
  
protected
   
end