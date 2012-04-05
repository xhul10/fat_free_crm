require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SubscriptionMailer do

  describe "processing new comments received via email" do

    xit "should add a comment to a contact" do
      
      @user = FactoryGirl.create(:user)
      @contact = FactoryGirl.create(:contact)

      comment_body = 'This comment should be added to the associated contact'

      mail = Mail.new(:from    => @user.email,
                      :to      => "crm-comment@example.com",
                      :subject => "RE: [contact:#{@contact.id}] John Smith",
                      :body    => comment_body)

      ##### FatFreeCRM::Mailman.new.router.route(mail)

      @contact.comments.size.should == 1
      c = @contact.comments.first
      c.user.should == @user
      c.comment.should include(comment_body)
    end
  end
end
