class ebs::params {

  $util_linux_package = $::osfamily ? {
    'debian' => 'util-linux',
    default => 'util-linux-ng'
  }
}
