bash "Deploy Meteor" do
  user "root"
  code <<-EOF
  cd /srv/www/skyveri_main_site/current/
  rm -rf ./bundle
  rm -rf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  mrt install
  meteor bundle tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  tar -xzf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  rm tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz

  echo "process.env.MONGO_URL = 'mongodb://skyveri_readonly:Feiun5s09@oceanic.mongohq.com:10016/skyveri_main'; process.env.PORT = 80; require('./bundle/main.js'); " > server.js
  chown deploy:www-data /srv/www/skyveri_main_site/current/server.js
  chown -R deploy:www-data /srv/www/skyveri_main_site/current/bundle
  monit restart node_web_app_skyveri_main_site
  EOF
end
