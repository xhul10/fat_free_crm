require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "/tasks/update.js.rjs" do
  include TasksHelper

  before(:each) do
    assigns[:current_user] = Factory(:user)
  end

  describe "Changing due date" do
    before(:each) do
      assigns[:task_before_update] = Factory(:task, :bucket => "due_asap")
      assigns[:task] = @task       = Factory(:task, :bucket => "due_tomorrow")
      assigns[:view] = "pending"
      assigns[:task_total] = stub_task_total("pending")
    end

    it "from Tasks tab: should remove task from current bucket and hide empty bucket" do
      request.env["HTTP_REFERER"] = "http://localhost/tasks"
      render "tasks/update.js.rjs"

      response.body.should include_text(%Q/$("task_#{@task.id}").replace("")/)
      response.body.should include_text(%Q/$("list_due_asap").visualEffect("fade"/)
    end

    it "from Tasks tab: should show updated task in a new bucket" do
      request.env["HTTP_REFERER"] = "http://localhost/tasks"
      render "tasks/update.js.rjs"
      response.should have_rjs(:insert, :top) do |rjs|
        with_tag("li[id=task_#{@task.id}]")
      end
      response.should include_text(%Q/$("task_#{@task.id}").visualEffect("highlight"/)
    end

    it "from Tasks tab: should update tasks sidebar" do
      request.env["HTTP_REFERER"] = "http://localhost/tasks"
      render "tasks/update.js.rjs"
      response.body.should have_rjs("sidebar") do |rjs|
        with_tag("div[id=filters]")
      end
      response.body.should include_text(%Q/$("filters").visualEffect("shake"/)
    end

    it "from asset page: should update task partial in place" do
      render "tasks/update.js.rjs"
      response.should have_rjs("task_#{@task.id}") do |rjs|
        with_tag("li[id=task_#{@task.id}]")
      end
    end

  end

  describe "Reassigning" do
    before(:each) do
      assigns[:current_user] = Factory(:user)
      assigns[:task_total] = stub_task_total("pending")
    end

    it "pending task to somebody from Tasks tab: should remove the task and show flash message (assigned)" do
      assignee = Factory(:user)
      assigns[:task_before_update] = Factory(:task, :assignee => nil)
      assigns[:task] = @task       = Factory(:task, :assignee => assignee)
      assigns[:view] = "pending"
      request.env["HTTP_REFERER"] = "http://localhost/tasks"

      render "tasks/update.js.rjs"
      response.body.should include_text(%Q/$("task_#{@task.id}").replace("")/)
      response.should include_text(%Q/$("tasks_flash").update("The task has been assigned to #{assignee.full_name}/)
      response.should include_text('$("tasks_flash").show()')
    end

    it "assigned tasks to me from Tasks tab: should remove the task and show flash message (pending)" do
      assignee = Factory(:user)
      assigns[:task_before_update] = Factory(:task, :assignee => assignee)
      assigns[:task] = @task       = Factory(:task, :assignee => nil)
      assigns[:view] = "assigned"
      request.env["HTTP_REFERER"] = "http://localhost/tasks?view=assigned"

      render "tasks/update.js.rjs"
      response.body.should include_text(%Q/$("task_#{@task.id}").replace("")/)
      response.should include_text('$("tasks_flash").update("The task has been moved to pending tasks')
      response.should include_text('$("tasks_flash").show()')
    end

    it "assigned tasks to somebody else from Tasks tab: should re-render task partial" do
      assigns[:task_before_update] = Factory(:task, :assignee => Factory(:user))
      assigns[:task] = @task       = Factory(:task, :assignee => Factory(:user))
      assigns[:view] = "assigned"
      request.env["HTTP_REFERER"] = "http://localhost/tasks?view=assigned"

      render "tasks/update.js.rjs"
      response.should have_rjs("task_#{@task.id}") do |rjs|
        with_tag("li[id=task_#{@task.id}]")
      end
    end

    it "from asset page: should should re-render task partial" do
      assigns[:task_before_update] = Factory(:task, :assignee => nil)
      assigns[:task] = @task       = Factory(:task, :assignee => Factory(:user))

      render "tasks/update.js.rjs"
      response.should have_rjs("task_#{@task.id}") do |rjs|
        with_tag("li[id=task_#{@task.id}]")
      end
    end

  end

  it "error: should re-disiplay [Edit Task] form and shake it" do
    assigns[:task_before_update] = Factory(:task)
    assigns[:task] = @task = Factory(:task)
    @task.errors.add(:error)

    render "tasks/update.js.rjs"
    response.should include_text(%Q/$("task_#{@task.id}").visualEffect("shake"/)
  end

end