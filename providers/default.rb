action :create do
  path = new_resource.path

  user = new_resource.user || new_resource.name
  group = new_resource.group || user

  server = new_resource.server || "localhost:8080"
  static_dir = new_resource.static_dir || "/opt/static/#{new_resource.name}"

  virtualenv = new_resource.virtualenv || "/opt/env/#{new_resource.name}"
  requirements = new_resource.requirements || "#{path}/requirements.pip"

  environment_variables = new_resource.environment_variables || {}

  # The directory within the main path that contains the settings module.
  # Usually this will be the main name of the app.
  # E.g.
  # myapp/
  #   manage.py
  #   api/
  #   myapp/    <-- We need the full path to this.
  #     settings.py
  #
  container_dir = new_resource.container_dir || "#{path}/#{new_resource.name}"


  # Set up an virtual env and install the requirements into it.
  #
  directory virtualenv do
    action :create
    recursive true
    owner user
    group group
  end

  python_virtualenv virtualenv do
    options "--no-site-packages --distribute"
    owner user
    group group
    action :create
  end

  python_pip "-r #{requirements}" do
    virtualenv virtualenv
    action :install
  end

  # Create the static dir and collect static files into there.
  #
  directory static_dir do
    action :create
    recursive true
    owner user
    group group
  end

  execute "collect static files" do
    command "#{virtualenv}/bin/python manage.py collectstatic --noinput"
    cwd path
    environment environment_variables
  end

  # This is a bit ugly but I can't find a nicer way to get variables into the
  # virtual env.
  # First we create a file with export statements for each variable.
  #
  template "#{virtualenv}/bin/custom_variables" do
    source "custom_variables.erb"
    cookbook "django_application"
    owner user
    group group
    variables(
      :environment_variables => environment_variables
    )
    mode 0644
  end
  # Then we add a line to source that custom variables file when we activate
  # the virtualenv. (We should avoid appending more than once.)
  #
  bash "append_to_activate" do
    user user
    code <<-EOF
      echo "source custom_variables" >> #{virtualenv}/bin/activate
    EOF
    not_if "grep -q custom_variables #{virtualenv}/bin/activate"
  end

  # Set up a gunicorn config file.
  #
  gunicorn_config "/etc/gunicorn/#{new_resource.name}.py" do
    listen server
    worker_timeout 30
    worker_processes 4
    owner user
    group group
    action :create
  end

  # We need a redirect on the server port to the django app and
  # a location that points to our collected static files.
  #
  template "#{node[:nginx][:dir]}/sites-available/#{new_resource.name}" do
    source "nginx-site.conf.erb"
    cookbook "django_application"
    owner "www-data"
    group group
    variables(
      :app_name => new_resource.name,
      :server => server,
      :static_dir => static_dir
    )
    mode 0644
  end

  nginx_site new_resource.name do
    enable true
  end
  nginx_site "default" do
    enable false
  end

  # Set up a task in supervisorctl.
  #
  template "/etc/supervisor/conf.d/#{new_resource.name}.conf" do
    source "supervisor.conf.erb"
    cookbook "django_application"
    user user
    group group
    variables(
      :app_name => new_resource.name,
      :user => user,
      :app_home => path,
      :container_dir => container_dir,
      :environment_variables => environment_variables,
      :env_home => virtualenv
    )
    mode 0644
    notifies :restart, "service[supervisor]"
  end
end

