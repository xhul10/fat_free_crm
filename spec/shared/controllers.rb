module SharedControllerSpecs

  describe "auto complete", :shared => true do
    before(:each) do
      @query = "Hello"
    end

    it "should do the search and find records that match autocomplete query" do
      post :auto_complete, :auto_complete_query => @query
      assigns[:query].should == @query
      assigns[:auto_complete].should == @auto_complete_matches # Each controller must define it.
    end
    
    it "should save current autocomplete controller in a session" do
      post :auto_complete, :auto_complete_query => @query

      # We don't save Admin/Users autocomplete controller in a session since Users are not
      # exposed through the Jumpbox.
      unless controller.class.to_s.starts_with?("Admin::")
        session[:auto_complete].should == @controller.controller_name.to_sym
      end
    end

    it "should render common/auto_complete template" do
      post :auto_complete, :auto_complete_query => @query
      response.should render_template("common/auto_complete")
    end
  end

  describe "discard", :shared => true do
    it "should discard the attachment without deleting it" do
      xhr :post, :discard, :id => @model.id, :attachment => @attachment.class.name, :attachment_id => @attachment.id
      assigns[:attachment].should == @attachment.reload               # The attachment should still exist.
      @model.send("#{@attachment.class.name.tableize}").should == []  # But no longer associated with the model.
      response.should render_template("common/discard")
    end

    it "should display flash warning when the model is no longer available" do
      @model.destroy

      xhr :post, :discard, :id => @model.id, :attachment => @attachment.class.name, :attachment_id => @attachment.id
      flash[:warning].should_not == nil
      response.body.should == "window.location.reload();"
    end

    it "should display flash warning when the attachment is no longer available" do
      @attachment.destroy

      xhr :post, :discard, :id => @model.id, :attachment => @attachment.class.name, :attachment_id => @attachment.id
      flash[:warning].should_not == nil
      response.body.should == "window.location.reload();"
    end
  end

end
