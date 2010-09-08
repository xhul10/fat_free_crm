# Fat Free CRM
# Copyright (C) 2008-2010 by Michael Dvorkin
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

class ApplicationController < ActionController::Base
  helper(application_helpers)
  helper_method :current_user_session, :current_user, :can_signup?
  helper_method :called_from_index_page?, :called_from_landing_page?

  before_filter :set_context
  before_filter "hook(:app_before_filter, self)"
  after_filter "hook(:app_after_filter, self)"

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  # protect_from_forgery # :secret => '165eb65bfdacf95923dad9aea10cc64a'

  # Common auto_complete handler for all core controllers.
  #----------------------------------------------------------------------------
  def auto_complete
    @query = params[:auto_complete_query]
    @auto_complete = hook(:auto_complete, self, :query => @query, :user => @current_user)
    if @auto_complete.empty?
      @auto_complete = controller_name.classify.constantize.my(:user => @current_user, :limit => 10).search(@query)
    else
      @auto_complete = @auto_complete.last
    end
    session[:auto_complete] = controller_name.to_sym
    render :template => "common/auto_complete", :layout => nil
  end

  # Common attach handler for all core controllers.
  #----------------------------------------------------------------------------
  def attach
    model = controller_name.classify.constantize.my(@current_user).find(params[:id])
    @attachment = params[:assets].classify.constantize.find(params[:asset_id])
    @attached = model.attach!(@attachment)
    @campaign = model.reload if model.is_a?(Campaign)

    respond_to do |format|
      format.js  { render :template => "common/attach" }
      format.xml { render :xml => model.reload.to_xml }
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

  # Common discard handler for all core controllers.
  #----------------------------------------------------------------------------
  def discard
    model = controller_name.classify.constantize.my(@current_user).find(params[:id])
    @attachment = params[:attachment].constantize.find(params[:attachment_id])
    model.discard!(@attachment)
    @campaign = model.reload if model.is_a?(Campaign)

    respond_to do |format|
      format.js  { render :template => "common/discard" }
      format.xml { render :xml => model.reload.to_xml }
    end

  rescue ActiveRecord::RecordNotFound
    respond_to_not_found(:html, :js, :xml)
  end

private
  #----------------------------------------------------------------------------
  def set_context
    ActiveSupport::TimeZone[session[:timezone_offset]] if session[:timezone_offset]
    ActionMailer::Base.default_url_options[:host] = request.host_with_port
    if Setting.locale
      I18n.locale = Setting.locale
    else
      # Pre-I18n settings that need to be reloaded. Use English message text since the actual locale is unknown.
      raise FatFreeCRM::ObsoleteSettings, <<-OBSOLETE
        It looks like you are upgrading from the older version of Fat Free CRM. Please review
        <b>config/settings.yml</b> file, and re-run<br><b>rake crm:settings:load</b> command
        in development and production environments.
      OBSOLETE
    end
  end

  #----------------------------------------------------------------------------
  def set_current_tab(tab = controller_name)
    @current_tab = tab
  end

  #----------------------------------------------------------------------------
  def current_user_session
    @current_user_session ||= Authentication.find
    if @current_user_session && @current_user_session.record.suspended?
      @current_user_session = nil
    end
    @current_user_session
  end

  #----------------------------------------------------------------------------
  def current_user
    @current_user ||= (current_user_session && current_user_session.record)
    if @current_user && @current_user.preference[:locale]
      I18n.locale = @current_user.preference[:locale]
    end
    User.current_user = @current_user
  end

  #----------------------------------------------------------------------------
  def require_user
    unless current_user
      store_location
      flash[:notice] = t(:msg_login_needed) if request.fullpath != "/"
      redirect_to login_url
      false
    end
  end

  #----------------------------------------------------------------------------
  def require_no_user
    if current_user
      store_location
      flash[:notice] = t(:msg_logout_needed)
      redirect_to profile_url
      false
    end
  end

  #----------------------------------------------------------------------------
  def store_location
    session[:return_to] = request.fullpath
  end

  #----------------------------------------------------------------------------
  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end

  #----------------------------------------------------------------------------
  def can_signup?
    [ :allowed, :needs_approval ].include? Setting.user_signup
  end

  #----------------------------------------------------------------------------
  def called_from_index_page?(controller = controller_name)
    if controller != "tasks"
      request.referer =~ %r(/#{controller}$)
    else
      request.referer =~ /tasks\?*/
    end
  end

  #----------------------------------------------------------------------------
  def called_from_landing_page?(controller = controller_name)
    request.referer =~ %r(/#{controller}/\w+)
  end

  #----------------------------------------------------------------------------
  def update_recently_viewed
    subject = instance_variable_get("@#{controller_name.singularize}")
    if subject
      Activity.log(@current_user, subject, :viewed)
    end
  end

  #----------------------------------------------------------------------------
  def respond_to_not_found(*types)
    asset = self.controller_name.singularize
    flick = case self.action_name
      when "destroy" then "delete"
      when "promote" then "convert"
      else self.action_name
    end
    if self.action_name == "show"
      flash[:warning] = t(:msg_asset_not_available, asset)
    else
      flash[:warning] = t(:msg_cant_do, :action => flick, :asset => asset)
    end
    respond_to do |format|
      format.html { redirect_to(:action => :index) }                         if types.include?(:html)
      format.js   { render(:update) { |page| page.reload } }                 if types.include?(:js)
      format.xml  { render :text => flash[:warning], :status => :not_found } if types.include?(:xml)
    end
  end

  #----------------------------------------------------------------------------
  def respond_to_related_not_found(related, *types)
    asset = self.controller_name.singularize
    asset = "note" if asset == "comment"
    flash[:warning] = t(:msg_cant_create_related, :asset => asset, :related => related)
    url = send("#{related.pluralize}_path")
    respond_to do |format|
      format.html { redirect_to(url) }                                       if types.include?(:html)
      format.js   { render(:update) { |page| page.redirect_to(url) } }       if types.include?(:js)
      format.xml  { render :text => flash[:warning], :status => :not_found } if types.include?(:xml)
    end
  end

  # Proxy current page for any of the controllers by storing it in a session.
  #----------------------------------------------------------------------------
  def current_page=(page)
    @current_page = session["#{controller_name}_current_page".to_sym] = page.to_i
  end

  #----------------------------------------------------------------------------
  def current_page
    page = params[:page] || session["#{controller_name}_current_page".to_sym] || 1
    @current_page = page.to_i
  end

  # Proxy current search query for any of the controllers by storing it in a session.
  #----------------------------------------------------------------------------
  def current_query=(query)
    @current_query = session["#{controller_name}_current_query".to_sym] = query
  end

  #----------------------------------------------------------------------------
  def current_query
    @current_query = params[:query] || session["#{controller_name}_current_query".to_sym] || ""
  end

end
