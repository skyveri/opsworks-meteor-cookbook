#
# Based on:
# https://github.com/aws/opsworks-cookbooks/blob/release-chef-11.4/deploy/definitions/opsworks_deploy.rb
#
# Ruby on Rails related code has been removed.
# Uses custom app config for SCM info. Do not specify "Repository Type" in App settings (in AWS console).
# Meteor installation code has been added.
#


define :meteor_deploy do
  application = params[:app]
  deploy = params[:deploy_data]
  app_config = params[:app_config]

  directory "#{deploy[:deploy_to]}" do
    group deploy[:group]
    owner deploy[:user]
    mode "0775"
    action :create
    recursive true
  end

  if app_config[:scm]
    ensure_scm_package_installed(app_config[:scm][:scm_type])

    prepare_git_checkouts(
      :user => deploy[:user],
      :group => deploy[:group],
      :home => deploy[:home],
      :ssh_key => app_config[:scm][:ssh_key]
    ) if app_config[:scm][:scm_type].to_s == 'git'

    prepare_svn_checkouts(
      :user => deploy[:user],
      :group => deploy[:group],
      :home => deploy[:home],
      :deploy => deploy,
      :application => application
    ) if app_config[:scm][:scm_type].to_s == 'svn'

    if app_config[:scm][:scm_type].to_s == 'archive'
      repository = prepare_archive_checkouts(app_config[:scm])
      node.set[:deploy][application][:scm] = {
        :scm_type => 'git',
        :repository => repository
      }
    elsif app_config[:scm][:scm_type].to_s == 's3'
      repository = prepare_s3_checkouts(app_config[:scm])
      node.set[:deploy][application][:scm] = {
        :scm_type => 'git',
        :repository => repository
      }
    end
  end

  deploy = node[:deploy][application]

  directory "#{deploy[:deploy_to]}/shared/cached-copy" do
    recursive true
    action :delete
    only_if do
      deploy[:delete_cached_copy]
    end
  end

  ruby_block "change HOME to #{deploy[:home]} for source checkout" do
    block do
      ENV['HOME'] = "#{deploy[:home]}"
    end
  end

  # setup deployment & checkout
  if app_config[:scm] && app_config[:scm][:scm_type] != 'other'
    Chef::Log.debug("Checking out source code of application #{application} with type #{deploy[:application_type]}")
    deploy deploy[:deploy_to] do
      provider Chef::Provider::Deploy.const_get(deploy[:chef_provider])
      if deploy[:keep_releases]
        keep_releases deploy[:keep_releases]
      end
      repository app_config[:scm][:repository]
      user deploy[:user]
      group deploy[:group]
      revision app_config[:scm][:revision]
      migrate deploy[:migrate]
      migration_command deploy[:migrate_command]
      environment deploy[:environment].to_hash
      symlink_before_migrate( deploy[:symlink_before_migrate] )
      action deploy[:action]

      case app_config[:scm][:scm_type].to_s
      when 'git'
        scm_provider :git
        enable_submodules deploy[:enable_submodules]
        shallow_clone deploy[:shallow_clone]
      when 'svn'
        scm_provider :subversion
        svn_username app_config[:scm][:user]
        svn_password app_config[:scm][:password]
        svn_arguments "--no-auth-cache --non-interactive --trust-server-cert"
        svn_info_args "--no-auth-cache --non-interactive --trust-server-cert"
      else
        raise "unsupported SCM type #{app_config[:scm][:scm_type].inspect}"
      end
      
      before_restart do
        bash "Restart Node" do
          user "root"
          code <<-EOH
          monit restart node_web_app_#{app_slug_name}
          EOH
      end

      before_migrate do
        # Check if domain name is set
        if deploy[:domains].length == 0
          Chef::Log.debug("Skipping Meteor installation of #{app_slug_name}. App does not have any domains configured.")
          next
        end

        # Using the first domain to create ROOT_URL for Meteor
        domain_name = deploy[:domains][0]

        if deploy[:ssl_support]
          protocol_prefix = "https://"
        else
          protocol_prefix = "http://"
        end

        tmp_dir = "/tmp/meteor_tmp"
        repo_dir = "#{deploy[:deploy_to]}/shared/cached-copy"
        mongo_url = app_config[:mongo_url]

        bash "Deploy Meteor" do
          code <<-EOH
          # Reset the Meteor temp directory
          rm -rf #{tmp_dir}
          mkdir -p #{tmp_dir}

          # Move files to the temp directory
          cp -R #{repo_dir}/. #{tmp_dir}

          # Create a Meteor bundle
          cd #{tmp_dir}
          mrt install
          meteor bundle bundled_app.tgz
          tar -xzf bundled_app.tgz

          # Copy the bundle folder into the release directory
          cp -R #{tmp_dir}/bundle #{release_path}
          chown -R deploy:www-data #{release_path}/bundle

          # cd into release directory
          cd #{release_path}

          # OpsWorks expects a server.js file
          echo 'process.env.ROOT_URL  = "#{protocol_prefix}#{domain_name}";' > ./server.js
          echo 'process.env.MONGO_URL = "#{mongo_url}";' >> ./server.js
          echo 'process.env.PORT = 80; require("./bundle/main.js");' >> ./server.js
          chown deploy:www-data ./server.js

          # Remove the temp directory
          rm -rf #{tmp_dir}
          EOH
        end

        link_tempfiles_to_current_release

        if deploy[:auto_npm_install_on_deploy]
          OpsWorks::NodejsConfiguration.npm_install(application, node[:deploy][application], release_path)
        end

        # run user provided callback file
        run_callback_from_file("#{release_path}/deploy/before_migrate.rb")
      end
    end
  end

  ruby_block "change HOME back to /root after source checkout" do
    block do
      ENV['HOME'] = "/root"
    end
  end

  template "/etc/logrotate.d/opsworks_app_#{application}" do
    backup false
    source "logrotate.erb"
    cookbook 'deploy'
    owner "root"
    group "root"
    mode 0644
    variables( :log_dirs => ["#{deploy[:deploy_to]}/shared/log" ] )
  end
end
