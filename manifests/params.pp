class ebs::params {

  $util_linux_package = $::osfamily ? {
    default => 'util-linux-ng'
  }
}
