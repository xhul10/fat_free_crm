require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/comments/new.html.haml" do
  include CommentsHelper

  before(:each) do
    assign(:comment, stub_model(Comment,
      :new_record? => true
    ))
  end

  it "should render new form" do
    render

    rendered.should include("hide()")
    rendered.should include("show()")
  end
end


