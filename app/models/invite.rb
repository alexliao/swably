class Invite < ActiveRecord::Base
  belongs_to :invitor, :class_name => 'User', :foreign_key => 'invitor_id'
  belongs_to :invitee, :class_name => 'User', :foreign_key => 'invitee_id'

  def facade(current_user = nil, options = {})
    ret = {}
    ret[:id] = self.id
    ret[:request_id] = self.request_id
    ret[:invite_code] = self.invite_code
    ret[:created_at] = self.created_at.to_i
    ret[:updated_at] = self.updated_at.to_i
    ret[:invitor] = self.invitor.facade(nil, options.merge(:names_only => true)) if self.invitor
    ret[:invitee] = self.invitee.facade(nil, options.merge(:names_only => true)) if self.invitee
    ret
  end

end
