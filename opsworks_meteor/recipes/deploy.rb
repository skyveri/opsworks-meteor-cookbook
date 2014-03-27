bash "Deploy Meteor" do
  user "root"
  code <<-EOF
  cd /tmp
  rm -rf meteor_tmp
  mkdir -p meteor_tmp
  cd meteor_tmp
  git clone git@github.com:skyveri/skyveri-main-site.git ./repo
  cd ./repo
  mrt install
  meteor bundle tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  tar -xzf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  rm -rf /srv/www/skyveri_main_site/current/bundle
  mv bundle /srv/www/skyveri_main_site/current/
  cd /srv/www/skyveri_main_site/current/
  echo "process.env.MONGO_URL = 'mongodb://skyveri_readonly:Feiun5s09@oceanic.mongohq.com:10016/skyveri_main'; process.env.PORT = 80; require('./bundle/main.js'); " > server.js
  monit restart node_web_app_skyveri_main_site
  EOF
end
