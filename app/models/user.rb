# Fat Free CRM
# Copyright (C) 2008-2009 by Michael Dvorkin
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
# 
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#------------------------------------------------------------------------------
# == Schema Information
# Schema version: 17
#
# Table name: users
#
#  id                :integer(4)      not null, primary key
#  uuid              :string(36)
#  username          :string(32)      default(""), not null
#  email             :string(64)      default(""), not null
#  first_name        :string(32)
#  last_name         :string(32)
#  title             :string(64)
#  company           :string(64)
#  alt_email         :string(64)
#  phone             :string(32)
#  mobile            :string(32)
#  aim               :string(32)
#  yahoo             :string(32)
#  google            :string(32)
#  skype             :string(32)
#  password_hash     :string(255)     default(""), not null
#  password_salt     :string(255)     default(""), not null
#  remember_token    :string(255)     default(""), not null
#  perishable_token  :string(255)     default(""), not null
#  openid_identifier :string(255)
#  last_request_at   :datetime
#  last_login_at     :datetime
#  current_login_at  :datetime
#  last_login_ip     :string(255)
#  current_login_ip  :string(255)
#  login_count       :integer(4)      default(0), not null
#  deleted_at        :datetime
#  created_at        :datetime
#  updated_at        :datetime
#

class User < ActiveRecord::Base
  
  has_one  :avatar, :as => :entity, :dependent => :destroy
  has_many :avatars # as owner who uploaded it, ex. Contact avatar
  has_many :accounts
  has_many :campaigns
  has_many :leads
  has_many :contacts
  has_many :opportunities
  has_many :permissions
  has_many :preferences
  has_many :shared_accounts, :through => :permissions, :source => :asset, :source_type => "Account", :class_name => "Account"
  named_scope :except, lambda { | user | { :conditions => "id != #{user.id}" } }
  uses_mysql_uuid
  acts_as_paranoid
  acts_as_authentic do |c|
    c.session_class = Authentication
    c.validates_uniqueness_of_login_field_options = { :message => "^This username has been already taken." }
    c.validates_uniqueness_of_email_field_options = { :message => "^There is another user with the same email." }
    c.validates_length_of_password_field_options  = { :minimum => 3 }
  end

  # validates_presence_of :username, :message => "^Please specify the username."
  # validates_presence_of :email,    :message => "^Please specify your email address."

  #----------------------------------------------------------------------------
  def name
    self.first_name.blank? ? self.username : self.first_name
  end

  #----------------------------------------------------------------------------
  def full_name
    self.first_name.blank? || self.last_name.blank? ? self.email : "#{self.first_name} #{self.last_name}"
  end

  #----------------------------------------------------------------------------
  def preference
    Preference.new(:user => self)
  end
  alias :pref :preference

  #----------------------------------------------------------------------------
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

end
