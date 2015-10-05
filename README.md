# ecryptfs

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

## Limitations

This module was tested on CentOS 6.x so far. For the AWS API authorization to work,
you have to assign a proper IAM role to an ec2 instance you're running this code on.
Example policy (tune Resource parameter to your liking):

```json

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

