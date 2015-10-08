class ebs (
  $skip_awscli_install = false
) inherits ebs::params {

  if $skip_awscli_install == false {
    require awscli_bundled
  }

  if ! defined(Package[$util_linux_package]) {
    package { $util_linux_package:
      ensure => present
    }
  }
}
