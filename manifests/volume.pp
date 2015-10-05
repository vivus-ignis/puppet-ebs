define ebs::volume (
  $device         = '/dev/sdb',
  $format         = 'ext4',
  $format_options = undef,
  $mount_options  = 'noatime',
  $mount_dir      = '/mnt'
) {

  require ebs

  Exec {
    path => '/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin'
  }

  validate_re($device, '^/dev/sd[b-z]$')

  $volume_id_file = "/var/lib/puppet/.ebs__${name}__volume_id"
  $aws_region = inline_template("<%= @ec2_placement_availability_zone.gsub(/.$/,'') %>")

  $device_attached = $::osfamily? {
    default => inline_template("<%= '/dev/xvd' << @device[-1] %>")
  }

  exec { "EBS volume ${name}: obtaining the volume id":
    command     => "aws ec2 describe-volumes --filters Name='tag:name',Values=${name} --query 'Volumes[*].{ID:VolumeId, State:State}' | grep 'ID' | cut -d':' -f 2 | tr -d ' \"' > ${volume_id_file}",
    unless      => "test -s ${volume_id_file}",
    environment => "AWS_DEFAULT_REGION=${aws_region}"
  } ->

  exec { "EBS volume ${name}: volume id sanity check":
    command => "[ `wc -l ${volume_id_file} | awk '{print \$1}'` -eq 1 ]"
  } ->

  exec { "EBS volume ${name}: attaching the volume":
    command     => "aws ec2 attach-volume --volume-id=`cat ${volume_id_file}` --instance-id $ec2_instance_id --device $device",
    environment => "AWS_DEFAULT_REGION=${aws_region}",
    unless      => "test -b ${device_attached}"
  } ->

  exec { "EBS volume ${name}: formatting the volume":
    command => "mkfs.${format} ${format_options} ${device_attached}",
    unless  => "lsblk -fn | grep `basename ${device_attached}` | grep ${format}",
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
