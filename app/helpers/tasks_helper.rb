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

module TasksHelper

  # Sidebar checkbox control for filtering tasks by due date -- used for
  # pending and assigned views only.
  #----------------------------------------------------------------------------
  def task_filter_checbox(view, filter, count)
    name = "filter_by_task_#{view}"
    checked = (session[name] ? session[name].split(",").include?(filter.to_s) : count > 0)
    check_box_tag("filters[]", filter, checked, :onclick => remote_function(:url => { :action => :filter, :view => view }, :with => "{filter: this.value, checked:this.checked}" ))
  end

  #----------------------------------------------------------------------------
  def filtered_out?(view, filter = nil)
    name = "filter_by_task_#{view}"
    if filter
      filters = (session[name].nil? ? [] : session[name].split(","))
      !filters.include?(filter.to_s)
    else
      session[name].blank?
    end
  end

  #----------------------------------------------------------------------------
  def link_to_task_edit(task, bucket)
    link_to_remote("Edit",
      :url    => edit_task_path(task),
      :method => :get,
      :with   => "{ bucket: '#{bucket}', view: '#{@view}', previous: crm.find_form('edit_task') }"
    )
  end

  #----------------------------------------------------------------------------
  def link_to_task_delete(task, bucket)
    link_to_remote("Delete!",
      :url    => task_path(task),
      :method => :delete,
      :with   => "{ bucket: '#{bucket}', view: '#{@view}' }",
      :before => visual_effect(:highlight, dom_id(task), :startcolor => "#ffe4e1")
    )
  end

  #----------------------------------------------------------------------------
  def link_to_task_complete(pending, bucket)
    onclick = "this.disable();"
    onclick << %Q/$("#{dom_id(pending, :name)}").style.textDecoration="line-through";/
    onclick << remote_function(:url => complete_task_path(pending), :method => :put, :with => "{ bucket: '#{bucket}' }")
  end

  #----------------------------------------------------------------------------
  def hide_task_and_possibly_bucket(id, bucket)
    update_page do |page|
      page[id].replace ""

      if Task.bucket_empty?(bucket, @current_user, @view)
        page["list_#{bucket}"].visual_effect :fade, :duration => 0.5
      end
    end
  end

  #----------------------------------------------------------------------------
  def replace_content(task, bucket = nil)
    partial = (task.assigned_to && task.assigned_to != @current_user.id) ? "assigned" : "pending"
    update_page do |page|
      page[dom_id(task)].replace_html :partial => "tasks/#{partial}", :collection => [ task ], :locals => { :bucket => bucket }
    end
  end

  #----------------------------------------------------------------------------
  def insert_content(task, bucket, view)
    update_page do |page|
      page["list_#{bucket}"].show
      page.insert_html :top, bucket, :partial => view, :collection => [ task ], :locals => { :bucket => bucket }
      page[dom_id(task)].visual_effect :highlight, :duration => 1.5
    end
  end

  #----------------------------------------------------------------------------
  def tasks_flash(message)
    update_page do |page|
      page[:tasks_flash].update message
      page[:tasks_flash].show
    end
  end

  #----------------------------------------------------------------------------
  def reassign(id)
    update_page do |page|
      if @view == "pending" && @task.assigned_to != @current_user.id
        page << hide_task_and_possibly_bucket(id, @task_before_update.bucket)
        page << tasks_flash("The task has been assigned to #{@task.assignee.full_name} (" << link_to("view assigned tasks", url_for(:controller => :tasks, :view => :assigned)) << ").")
      elsif @view == "assigned" && @task.assigned_to.blank?
        page << hide_task_and_possibly_bucket(id, @task_before_update.bucket)
        page << tasks_flash("The task has been moved to pending tasks (" << link_to("view pending tasks", tasks_url) << ").")
      else
        page << replace_content(@task, @task.bucket)
      end
      page << refresh_sidebar(:index, :filters)
    end
  end

  #----------------------------------------------------------------------------
  def reschedule(id)
    update_page do |page|
      page << hide_task_and_possibly_bucket(id, @task_before_update.bucket)
      page << insert_content(@task, @task.bucket, @view)
      page << refresh_sidebar(:index, :filters)
    end
  end

end
