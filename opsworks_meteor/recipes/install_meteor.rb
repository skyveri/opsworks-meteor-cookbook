bash "Install Meteor" do
  Chef::Log.debug("Starting Meteor install script.")

  code <<-EOF
  curl https://install.meteor.com | /bin/sh
  npm install -g meteorite
  EOF

  Chef::Log.debug("Finished Meteor install script.")
end
