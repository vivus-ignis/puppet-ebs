# ebs

#### Table of Contents

1. [Overview](#overview)
2. [Usage - Configuration options and additional functionality](#usage)
3. [Limitations - OS compatibility, etc.](#limitations)

## Overview

This module provides allows to manage EBS volumes (attach, format, mount).
Volumes should be created outside of puppet, for example, using CloudFormation.
The module performs a lookup searching for a volume in question by a 'name' tag's
value.

All the interactions with AWS API are performed with aws commandline utilities.

## Usage

Be sure to create a volume beforehand. E.g., here is a snippet for CloudFormation:

```json
"JenkinsMasterStorageVolume": {
  "Type": "AWS::EC2::Volume",
  "Properties": {
    "Encrypted": true,
    "AvailabilityZone": "eu-west-1a",
    "Size": 100,
    "Tags": [
      {
        "Key": "name",
        "Value": "jenkins"
      }
    ]
  }
},
```

Or awscli:

```bash
aws ec2 create-volume --availability-zone $${AWS_DEFAULT_REGION}a \
  --size 1 --encrypted --volume-type standard \
  --query '{id:VolumeId}' \
  | grep '"id"' | awk '{print $$2}' \
  | tr -d '"' | perl -pe chomp > .volume_id
aws ec2 create-tags --resources `cat .volume_id` \
  --tags Key=name,Value=jenkins
```

And then in your puppet code you can create resources like this:

```puppet
ebs::volume { 'jenkins':             # so we look for an EBS volume that has name:jenkins tag set
  device         => '/dev/sdj',      # /dev/sdb by default
  format         => 'ext3',          # ext3 by default
  format_options => '-L jenkins',    # this will be passed to mkfs.ext3 AS IS, string format
  mount_dir      => '/mnt/jenkins',  # /mnt by default
  mount_options  => 'nodev, noatime' # single string, fstab format, 'noatime' by default
}
```

`mount_dir` directory will be created if it doesn't exist (so manage it
outside of this module to ensure custom owner/group/mode parameters).

Also, please be very careful with `format` option: if a volume was already formatted with,
say, 'ext4' and you set this parameter to something else ( ext3 ) -- a volume will
be reformatted and you will lose your data.

## Limitations

This module was tested on CentOS 6.x so far. For the AWS API authorization to work,
you have to assign a proper IAM role to an ec2 instance you're running this code on.
Example policy (tune Resource parameter to your liking):

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1444046341000",
            "Effect": "Allow",
            "Action": [
                "ec2:DescribeVolumes",
                "ec2:AttachVolume"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

*!!ATTENTION!!* I've discovered a bug on my CentOS 6.x system: when you format a volume
as an ext4 filesystem, it appears to lsblk as ext3 on a next volume attachment. This
causes puppet to FORMAT an already formetted partition (as it thinks that the configuration
is wrong -- we want an 'ext4' from it but it sees 'ext3').

For the time being, 'ext3' will be set as the default filesystem parameter to avoid
hitting this bug accidentally. At the same time, I encourage you to test your ebs::volume
resources on test machines with subsequent re-attaches (e.g. by terminating an instance and
reusing the volume on another one) BEFORE going to production.
