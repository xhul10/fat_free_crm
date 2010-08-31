Then /^I move the mouse over "([^\"]*)"$/ do |id|
  begin
    Capybara.current_session.driver.browser.execute_script("$('#{id}').onmouseover();")
  rescue Capybara::NotSupportedByDriverError
  end
end

Then /^I fire the "([^"]*)" event on "([^"]*)"$/ do |event, id|
  begin
    Capybara.current_session.driver.browser.execute_script("$('#{id}').simulate('#{event}');")
    sleep 1
  rescue Capybara::NotSupportedByDriverError
  end
end

Then /^I fire the "([^"]*)" event on css selector "([^"]*)"(?:\[([\d]*)\])?$/ do |event, selector, index|
  index ||= 0
  begin
    Capybara.current_session.driver.browser.execute_script("$$('#{selector}')[#{index}].simulate('#{event}');")
    sleep 1
  rescue Capybara::NotSupportedByDriverError
  end
end

