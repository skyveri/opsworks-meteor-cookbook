bash "Deploy Meteor" do
  user "root"

  Chef::Log.debug("Starting to loop through each app.")

  node[:deploy].each do |app_slug_name, deploy|

    if deploy[:domains].length == 0
      Chef::Log.debug("Skipping deploy::nodejs application #{application} does not have any domains configured.")
      next
    end

    domain_name = deploy[:domains][0]

    if deploy[:ssl_support]
      protocol_prefix = "https://"
    else
      protocol_prefix = "http://"
    end
  
    Chef::Log.debug("Using the first domain to create ROOT_URL for Meteor.")
    Chef::Log.debug("ROOT_URL: #{protocol_prefix}#{domain_name}")
    Chef::Log.debug("App slug name (the app_slug_name variable): #{app_slug_name}")
  
    code <<-EOF
    cd /srv/www/#{app_slug_name}/current/
  
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
    echo "process.env.ROOT_URL  = '#{protocol_prefix}#{domain_name}';" > server.js
    echo "process.env.MONGO_URL = '#{node[:meteor][:MONGO_URL]}';" >> server.js
    echo "process.env.PORT = 80; require('./bundle/main.js'); " >> server.js
    chown    deploy:www-data ./server.js
    chown -R deploy:www-data ./bundle
    
    echo "123" > server.js
  
    mv /tmp/meteor_tmp/config ./
    mv /tmp/meteor_tmp/log ./
    mv /tmp/meteor_tmp/opsworks.js ./
    mv /tmp/meteor_tmp/public ./
    mv /tmp/meteor_tmp/tmp ./
  
    monit restart node_web_app_#{app_slug_name}
    EOF
    
    Chef::Log.debug("Finished running commands for app #{app_slug_name}.")

  end

end
