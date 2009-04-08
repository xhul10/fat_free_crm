# == Schema Information
# Schema version: 17
#
# Table name: comments
#
#  id               :integer(4)      not null, primary key
#  user_id          :integer(4)
#  commentable_id   :integer(4)
#  commentable_type :string(255)
#  private          :boolean(1)
#  title            :string(255)     default("")
#  comment          :text
#  created_at       :datetime
#  updated_at       :datetime
#

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Comment do
  before(:each) do
    @valid_attributes = {
      :user => mock_model(User),
      :commentable => mock_model(Campaign),
      :comment => "Blah"
    }
  end

  it "should create a new instance given valid attributes" do
    Comment.create!(@valid_attributes)
  end
end
