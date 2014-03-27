bash "Deploy Meteor" do
  user "root"
  code <<-EOF
  cd /srv/www/skyveri_main_site/current/

  rm -rf /tmp/meteor_tmp
  mkdir -p /tmp/meteor_tmp

  mv ./config /tmp/meteor_tmp
  mv ./log /tmp/meteor_tmp
  mv ./opsworks.js /tmp/meteor_tmp
  mv ./public /tmp/meteor_tmp
  mv ./tmp /tmp/meteor_tmp

  rm -rf ./bundle
  rm -rf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  mrt install
  meteor bundle tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  tar -xzf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  rm tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  echo "process.env.ROOT_URL  = '#{node[:skyveri][:skyveri_main_site][:ROOT_URL]}';" > server.js
  echo "process.env.MONGO_URL = '#{node[:skyveri][:skyveri_main_site][:MONGO_URL]}';" >> server.js
  echo "process.env.PORT = 80; require('./bundle/main.js'); " >> server.js
  chown deploy:www-data /srv/www/skyveri_main_site/current/server.js
  chown -R deploy:www-data /srv/www/skyveri_main_site/current/bundle

  mv /tmp/meteor_tmp/config ./
  mv /tmp/meteor_tmp/log ./
  mv /tmp/meteor_tmp/opsworks.js ./
  mv /tmp/meteor_tmp/public ./
  mv /tmp/meteor_tmp/tmp ./

  monit restart node_web_app_skyveri_main_site
  EOF
end
