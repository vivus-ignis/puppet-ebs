ebs::volume { 'vagrant_test':
  format    => 'ext3',
  mount_dir => '/mnt/ebs_vagrant_test'
} ->

file { '/mnt/ebs_vagrant_test/file01':
  content => 'foo'
}
