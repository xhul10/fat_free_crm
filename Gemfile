source :rubygems

# Removes a gem dependency
def remove(name)
  @dependencies.reject! {|d| d.name == name }
end

# Replaces an existing gem dependency (e.g. from gemspec) with an alternate source.
def gem(name, *args)
  remove(name)
  super
end

# Load development dependencies from gemspec
gemspec

# Bundler no longer treats runtime dependencies as base dependencies.
# The following code restores this behaviour.
# (See https://github.com/carlhuda/bundler/issues/1041)
spec = Bundler.load_gemspec(Dir["./{,*}.gemspec"].first)
spec.runtime_dependencies.each do |dep|
  gem dep.name, *(dep.requirement.as_list)
end

gem 'ransack',      :git => "git://github.com/fatfreecrm/ransack.git"
gem 'chosen-rails', :git => "git://github.com/fatfreecrm/chosen-rails.git"

# Remove fat_free_crm from dependencies, to stop it from being auto-required.
remove 'fat_free_crm'

gem 'pg', '~> 0.13.2'

group :development, :test do
  gem 'rspec-rails'
  gem 'steak', :require => false
  gem 'headless'
  unless ENV["CI"]
    gem 'ruby-debug',   :platform => :mri_18
    gem 'ruby-debug19', :platform => :mri_19
  end
end
