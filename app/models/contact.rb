# == Schema Information
# Schema version: 11
#
# Table name: contacts
#
#  id          :integer(4)      not null, primary key
#  uuid        :string(36)
#  user_id     :integer(4)
#  assigned_to :integer(4)
#  reports_to  :integer(4)
#  first_name  :string(64)      default(""), not null
#  last_name   :string(64)      default(""), not null
#  access      :string(8)       default("Private")
#  title       :string(64)
#  department  :string(64)
#  source      :string(32)
#  email       :string(64)
#  alt_email   :string(64)
#  phone       :string(32)
#  mobile      :string(32)
#  blog        :string(128)
#  linkedin    :string(128)
#  facebook    :string(128)
#  twitter     :string(128)
#  address     :string(255)
#  born_on     :date
#  do_not_call :boolean(1)      not null
#  notes       :text
#  deleted_at  :datetime
#  created_at  :datetime
#  updated_at  :datetime
#

class Contact < ActiveRecord::Base
  belongs_to :user
  uses_mysql_uuid
  acts_as_paranoid
  
  #----------------------------------------------------------------------------
  def full_name
    self.first_name << " " << self.last_name
  end

end
