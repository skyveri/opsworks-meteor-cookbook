node[:deploy].each do |app_slug_name, app_deploy|
  deploy_to = app_deploy[:deploy_to]

  deploy "#{deploy_to}" do
    # Test
  end
end
