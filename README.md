#Overview

`django_application` is a resource that takes a path containing a django
application and then sets the application up to be run behind gunicorn & nginx
(and also allows it to be controlled with supervisor).


#Resources
```
attribute :path, :kind_of => String, :required => true
attribute :name, :kind_of => String, :name_attribute => true
attribute :user, :kind_of => String, :required => false
attribute :group, :kind_of => String, :required => false
attribute :virtualenv, :kind_of => String, :required => false
attribute :requirements, :kind_of => String, :required => false
attribute :server, :kind_of => String, :required => false
attribute :static_dir, :kind_of => String, :required => false
attribute :container_dir, :kind_of => String, :required => false
```


#Usage
Add it to the metadata.
```
depends "django_application"
```

And then use it in a recipe.
```
django_application "coolApp" do
  path "/opt/coolApp"
  user coolApp
end
```


#What it wants
Though a lot of the settings can be changed, by default it will assume the following structure:
```
/opt/coolApp/
  requirements.pip
  manage.py
  coolApp/
    settings.py
```


#What it does
`$name` is the name given to the `django_application` resource. In the usage example, this is `coolApp`.

* Sets up a virtual env (by default in `/opt/env/$name`) and installs the requirements.pip file into it.
* Collects all static content (by default to `/opt/static/$name`).
* Sets up a gunicorn worker for the django app.
* Sets up a nginx to serve the collected static files and the gunicorn worker
* Creates a supervisor task.

