bash "Deploy Meteor" do
  user "root"
  code <<-EOF
  cd /srv/www/skyveri_main_site/current/
  mrt install
  rm -r bundle
  meteor bundle tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  tar -xzf tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  rm tmp_f90e9fkjkjf0s0esre0r9034932952359sfd90.tgz
  EOF
end
