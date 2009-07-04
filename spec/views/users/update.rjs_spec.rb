require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')
 
describe "/users/update.js.rjs" do
  include UsersHelper
  
  before(:each) do
    login_and_assign
    assigns[:user] = @user = @current_user
  end

  describe "no errors:" do
    it "should flip [Edit Profile] form" do
      render "users/update.js.rjs"
      response.should_not have_rjs("user_#{@user.id}")
      response.should include_text('crm.flip_form("edit_profile")')
    end
  end # no errors

  describe "validation errors :" do
    before(:each) do
      @user.errors.add(:error)
    end

    it "should redraw the [Edit Profile] form and shake it" do
      render "users/update.js.rjs"
      response.should have_rjs("edit_profile") do |rjs|
        with_tag("form[class=edit_user]")
      end
      response.should include_text('$("edit_profile").visualEffect("shake"')
      # response.should include_text('focus()')
    end
  end # errors
end