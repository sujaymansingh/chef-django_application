actions :create
default_action :create

attribute :path, :kind_of => String, :required => true
attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String, :required => false
attribute :group, :kind_of => String, :required => false
attribute :virtualenv, :kind_of => String, :required => false
attribute :requirements, :kind_of => String, :required => false
attribute :server, :kind_of => String, :required => false
attribute :static_dir, :kind_of => String, :required => false
attribute :container_dir, :kind_of => String, :required => false
attribute :environment_variables, :kind_of => Hash, :required => false


def initialize(*args)
  super
  @action = :create

  @run_context.include_recipe "python"
  @run_context.include_recipe "nginx"
  @run_context.include_recipe "gunicorn"
  @run_context.include_recipe "supervisord"
end
