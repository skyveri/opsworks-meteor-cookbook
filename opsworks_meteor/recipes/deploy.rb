bash "Install Meteor" do
  user "ubuntu"
  command "curl https://install.meteor.com | /bin/sh"
  cwd "/srv/www/skyveri_main_site/current"
end
