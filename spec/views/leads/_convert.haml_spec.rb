require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/leads/convert.html.erb" do
  include LeadsHelper
  
  before(:each) do
    login_and_assign
    @account = Factory(:account)
    assign(:lead, Factory(:lead))
    assign(:users, [ @current_user ])
    assign(:account, @account)
    assign(:accounts, [ @account ])
    assign(:opportunity, Factory(:opportunity))
  end

  it "should render [convert lead] form" do
    view.should_receive(:render).with(hash_including(:partial => "leads/opportunity"))
    view.should_receive(:render).with(hash_including(:partial => "leads/convert_permissions"))

    render
    rendered.should have_tag("form[class=edit_lead]")
  end

end


