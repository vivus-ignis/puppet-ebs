# -*- mode: ruby -*-
# vi: set ft=ruby :

$user_data = File.read("user_data.sh")

$puppet_install = <<SCRIPT
  if [ ! -x /usr/bin/puppet ]; then
    rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-6.noarch.rpm
    yum install -y puppet
  fi
SCRIPT

$bats_install = <<SCRIPT
if [ ! -x /usr/local/bin/bats ]; then
  cd /tmp
  rm -rf bats
  wget -q -O v0.4.0.tar.gz https://github.com/sstephenson/bats/archive/v0.4.0.tar.gz
  tar xzf v0.4.0.tar.gz
  cd bats-0.4.0
  ./install.sh /usr/local
fi
SCRIPT

$bats_run = <<SCRIPT
/usr/local/bin/bats /vagrant/bats
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = "puppetlabs/centos-6.6-64-nocm"

  config.vm.box = 'dummy'
  config.vm.provider :aws do |aws, override|
    aws.access_key_id            = ENV['AWS_ACCESS_KEY_ID']
    aws.secret_access_key        = ENV['AWS_SECRET_ACCESS_KEY']
    aws.region                   = ENV['AWS_DEFAULT_REGION']
    aws.keypair_name             = ENV['AWS_KEYPAIR']
    aws.ami                      = ENV['AWS_AMI']
    aws.associate_public_ip      = true
    aws.instance_type            = 't2.micro'
    aws.subnet_id                = ENV['AWS_SUBNET_ID']
    aws.security_groups          = ENV['AWS_SECURITY_GROUPS'].split.to_a  # ssh, egress
    aws.iam_instance_profile_arn = ENV['AWS_IAM_PROFILE']
    aws.user_data                = $user_data
    aws.tags = {
      "vagrant"                    => true,
    }

    override.ssh.username         = ENV['AWS_SSH_USERNAME']
    override.ssh.private_key_path = ENV['AWS_SSH_KEY']
  end


  config.vm.provision 'shell', inline: $puppet_install
  config.vm.provision 'shell', inline: $bats_install

  config.vm.provision "puppet" do |puppet|
    puppet.module_path    = [ '..', 'modules' ]
    puppet.options        = '--verbose --debug' if ENV['VAGRANT_DEBUG']
    puppet.manifests_path = "manifests"
    puppet.manifest_file  = "vagrant.pp"
  end

  config.vm.provision 'shell', inline: $bats_run
end
