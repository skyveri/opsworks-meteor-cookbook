node[:deploy].each do |app_slug_name, deploy|
  deploy deploy[:deploy_to] do

    before_symlink do
      if deploy[:domains].length == 0
        Chef::Log.debug("Skipping Meteor installation of #{application}. App does not have any domains configured.")
        next
      end

      # Using the first domain to create ROOT_URL for Meteor
      domain_name = deploy[:domains][0]

      if deploy[:ssl_support]
        protocol_prefix = "https://"
      else
        protocol_prefix = "http://"
      end

      current_release = release_path
      tmp_dir = "/tmp/meteor_tmp"
      repo_dir = "#{new_resource[:deploy_to]}/shared/#{new_resource[:repository_cache]}"
      mongo_url = node[:meteor][:MONGO_URL]

      execute "Deploy Meteor" do
        user "root"

        # Reset the Meteor temp directory
        command "rm -rf #{tmp_dir}"
        command "mkdir -p #{tmp_dir}"
        # Move files to the temp directory
        command "cp #{repo_dir}/. #{tmp_dir} -R"

        # Create a Meteor bundle
        cwd "#{tmp_dir}"
        command "mrt install"
        command "meteor bundle bundled_app.tgz"
        command "tar -xzf bundled_app.tgz"

        # Copy the bundle folder into the release directory
        command "cp #{tmp_dir}/bundle #{current_release} -R"
        command "chown -R deploy:www-data #{current_release}/bundle"

        # OpsWorks expects a server.js file
        command "echo \"process.env.ROOT_URL  = '#{protocol_prefix}#{domain_name}';\" > #{current_release}/server.js"
        command "echo \"process.env.MONGO_URL = '#{mongo_url}';\" >> #{current_release}/server.js"
        command "echo \"process.env.PORT = 80; require('./bundle/main.js');\" >> #{current_release}/server.js"
        command "chown deploy:www-data #{current_release}/server.js"

      end

      Chef::Log.debug("ROOT_URL: #{protocol_prefix}#{domain_name}")
      Chef::Log.debug("app_slug_name: #{app_slug_name}")
      Chef::Log.debug("current_release: #{current_release}")
      Chef::Log.debug("Finished running commands for app #{app_slug_name}.")
    end
  end
end
