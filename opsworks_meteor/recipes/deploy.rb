bash "Deploy Meteor" do
  user "root"
  code <<-EOF
  cd /srv/www/skyveri_main_site/current/
  mrt install
  meteor bundle myapp.tgz
  tar -xzf myapp.tgz
  EOF
end
