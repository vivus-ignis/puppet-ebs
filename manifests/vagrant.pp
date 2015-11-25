ebs::volume { 'vagrant_test':
  format    => 'ext4',
  mount_dir => '/mnt/ebs_vagrant_test'
} ->

file { '/mnt/ebs_vagrant_test/file01':
  content => 'foo'
}
