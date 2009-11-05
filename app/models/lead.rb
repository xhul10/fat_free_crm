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
# Schema version: 23
#
# Table name: leads
#
#  id          :integer(4)      not null, primary key
#  user_id     :integer(4)
#  campaign_id :integer(4)
#  assigned_to :integer(4)
#  first_name  :string(64)      default(""), not null
#  last_name   :string(64)      default(""), not null
#  access      :string(8)       default("Private")
#  title       :string(64)
#  company     :string(64)
#  source      :string(32)
#  status      :string(32)
#  referred_by :string(64)
#  email       :string(64)
#  alt_email   :string(64)
#  phone       :string(32)
#  mobile      :string(32)
#  blog        :string(128)
#  linkedin    :string(128)
#  facebook    :string(128)
#  twitter     :string(128)
#  address     :string(255)
#  rating      :integer(4)      default(0), not null
#  do_not_call :boolean(1)      not null
#  deleted_at  :datetime
#  created_at  :datetime
#  updated_at  :datetime
#
class Lead < ActiveRecord::Base
  belongs_to  :user
  belongs_to  :campaign
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to
  has_one     :contact, :dependent => :nullify # On destroy keep the contact, but nullify its lead_id
  has_many    :tasks, :as => :asset, :dependent => :destroy, :order => 'created_at DESC'
  has_many    :activities, :as => :subject, :order => 'created_at DESC'

  named_scope :only, lambda { |filters| { :conditions => [ "status IN (?)" + (filters.delete("other") ? " OR status IS NULL" : ""), filters ] } }
  named_scope :converted, :conditions => "status='converted'"
  named_scope :for_campaign, lambda { |id| { :conditions => [ "campaign_id=?", id ] } }
  named_scope :created_by, lambda { |user| { :conditions => "user_id = #{user.id}" } }
  named_scope :assigned_to, lambda { |user| { :conditions => "assigned_to = #{user.id}" } }

  simple_column_search :first_name, :last_name, :company, :escape => lambda { |query| query.gsub(/[^\w\s\-\.']/, "").strip }
  uses_user_permissions
  acts_as_commentable
  acts_as_paranoid

  validates_presence_of :first_name, :message => "^Please specify first name."
  validates_presence_of :last_name, :message => "^Please specify last name."
  validate :users_for_shared_access

  after_create  :increment_leads_count
  after_destroy :decrement_leads_count

  SORT_BY = {
    "first name"   => "leads.first_name ASC",
    "last name"    => "leads.last_name ASC",
    "company"      => "leads.company ASC",
    "rating"       => "leads.rating DESC",
    "date created" => "leads.created_at DESC",
    "date updated" => "leads.updated_at DESC"
  }

  # Default values provided through class methods.
  #----------------------------------------------------------------------------
  def self.per_page ;  20                      ; end
  def self.outline  ;  "long"                  ; end
  def self.sort_by  ;  "leads.created_at DESC" ; end
  def self.first_name_position ;  "before"     ; end

  # Save the lead along with its permissions.
  #----------------------------------------------------------------------------
  def save_with_permissions(params)
    self.campaign = Campaign.find(params[:campaign]) unless params[:campaign].blank?
    if self.access == "Campaign" && self.campaign # Copy campaign permissions.
      save_with_model_permissions(Campaign.find(self.campaign_id))
    else
      super(params[:users]) # invoke :save_with_permissions in plugin.
    end
  end

  # Update lead attributes taking care of campaign lead counters when necessary.
  #----------------------------------------------------------------------------
  def update_with_permissions(attributes, users)
    if self.campaign_id == attributes[:campaign_id] # Same campaign (if any).
      super(attributes, users)                      # See lib/fat_free_crm/permissions.rb
    else                                            # Campaign has been changed -- update lead counters...
      decrement_leads_count                         # ..for the old campaign...
      lead = super(attributes, users)               # Assign new campaign.
      increment_leads_count                         # ...and now for the new campaign.
      lead
    end
  end

  # Promote the lead by creating contact and optional opportunity. Upon
  # successful promotion Lead status gets set to :converted.
  #----------------------------------------------------------------------------
  def promote(params)
    account     = Account.create_or_select_for(self, params[:account], params[:users])
    opportunity = Opportunity.create_for(self, account, params[:opportunity], params[:users])
    contact     = Contact.create_for(self, account, opportunity, params)

    return account, opportunity, contact
  end

  #----------------------------------------------------------------------------
  def convert
    update_attribute(:status, "converted")
  end

  #----------------------------------------------------------------------------
  def reject
    update_attribute(:status, "rejected")
  end

  #----------------------------------------------------------------------------
  def full_name(format = nil)
    if format.nil? || format == "before"
      "#{self.first_name} #{self.last_name}"
    else
      "#{self.last_name}, #{self.first_name}"
    end
  end
  alias :name :full_name

  private
  #----------------------------------------------------------------------------
  def increment_leads_count
    if self.campaign_id
      Campaign.increment_counter(:leads_count, self.campaign_id)
    end
  end

  #----------------------------------------------------------------------------
  def decrement_leads_count
    if self.campaign_id
      Campaign.decrement_counter(:leads_count, self.campaign_id)
    end
  end

  # Make sure at least one user has been selected if the lead is being shared.
  #----------------------------------------------------------------------------
  def users_for_shared_access
    errors.add(:access, "^Please specify users to share the lead with.") if self[:access] == "Shared" && !self.permissions.any?
  end

end
