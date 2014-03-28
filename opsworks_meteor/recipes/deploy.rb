node[:deploy].each do |app_slug_name, app_deploy|
  deploy_to = app_deploy[:deploy_to]

  deploy deploy_to do

    before_symlink do
      if new_resource[:domains].length == 0
        Chef::Log.debug("Skipping Meteor installation of #{app_slug_name}. App does not have any domains configured.")
        next
      end

      # Using the first domain to create ROOT_URL for Meteor
      domain_name = new_resource[:domains][0]

      if new_resource[:ssl_support]
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

      Chef::Log.debug("Finished running commands for #{current_release}")
    end
  end
end
