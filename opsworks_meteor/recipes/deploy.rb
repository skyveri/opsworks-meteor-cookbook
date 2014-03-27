bash "Install Meteor" do
  user "root"
  code <<-EOH
  echo "Hello OpsWorks World" > /etc/motd
  EOH
  code <<-EOF
  curl https://install.meteor.com | /bin/sh
  cd /tmp
  meteor create myapp
  EOF
end
