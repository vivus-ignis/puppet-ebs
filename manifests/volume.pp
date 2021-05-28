define ebs::volume (
  $device          = '/dev/sdz',
  $device_attached = '/dev/xvdad',
  $format          = 'ext3',
  $format_options  = undef,
  $mount_options   = 'noatime',
  $mount_dir       = '/mnt'
) {

  require ebs

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin'
  }

  $volume_id_file = "${puppet_vardir}/.ebs__${name}__volume_id"
  $aws_region = $facts['ec2_metadata']['placement']['region']
  $ec2_instance_id =  $facts['ec2_metadata']['instance-id']

  exec { "EBS volume ${name}: obtaining the volume id":
    command     => "aws ec2 describe-volumes --filters Name='tag:Name',Values=${name} --query 'Volumes[*].{ID:VolumeId, State:State}' | grep 'ID' | cut -d':' -f 2 | tr -d ' \",' > ${volume_id_file}",
    unless      => "test -s ${volume_id_file}",
    environment => "AWS_DEFAULT_REGION=${aws_region}"
  } ->

  exec { "EBS volume ${name}: volume id sanity check":
    command => "[ `wc -l ${volume_id_file} | awk '{print \$1}'` -eq 1 ]",
    refreshonly => true,
    subscribe   => Exec["EBS volume ${name}: obtaining the volume id"],
  } ->

  exec { "EBS volume ${name}: attaching the volume":
    command     => "aws ec2 attach-volume --volume-id `cat ${volume_id_file}` --instance-id $ec2_instance_id --device $device",
    environment => "AWS_DEFAULT_REGION=${aws_region}",
    unless      => "test -b ${device_attached}",
  } ->

  exec { "EBS volume ${name}: waiting for the volume to be attached":
    command     => "lsblk -fn ${device_attached}",
    tries       => 6,
    try_sleep   => 10,
    logoutput   => true,
    refreshonly => true,
    subscribe   => Exec["EBS volume ${name}: attaching the volume"],
  } ->

  exec { "EBS volume ${name}: formatting the volume":
    command   => "mkfs.${format} ${format_options} ${device_attached}",
    unless    => "lsblk -fn ${device_attached} | grep -q ' ${format} '",
    logoutput => true
  } ->

  exec { "EBS volume ${name}: creating the mount directory":
    command => "mkdir -p ${mount_dir}",
    unless  => "test -d ${mount_dir}"
  } ->

  mount { $mount_dir:
    ensure  => mounted,
    device  => $device_attached,
    fstype  => $format,
    options => $mount_options
  }

}
