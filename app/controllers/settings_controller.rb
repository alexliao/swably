require 'yaml'
class SettingsController < ApplicationController
  include CommonHelper

  def unsubscribe
    @email = params[:email]
    ExcludeEmail.remove(@email)
    ExcludeEmail.add(@email)
  end
  
  def subscribe
    @email = params[:email]
    ExcludeEmail.remove(@email)
  end
end