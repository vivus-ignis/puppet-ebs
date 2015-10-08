default:
	bundle exec rake validate
	. .exports && vagrant provision

install: volume instance

instance:
	. .exports && vagrant up

volume: .volume_id
	. .exports && aws ec2 create-tags --resources `cat .volume_id` \
	  --tags Key=name,Value=vagrant_test

.volume_id:
	. .exports && aws ec2 create-volume --availability-zone $${AWS_DEFAULT_REGION}a \
	  --size 1 --encrypted --volume-type standard \
	  --query '{id:VolumeId}' \
	  | grep '"id"' | awk '{print $$2}' \
	  | tr -d '"' | perl -pe chomp > .volume_id

clean: cleanebs
	. .exports && vagrant destroy -f
	rm -f .volume_id

cleanebs:
	-vagrant ssh -c 'sudo umount /mnt/ebs_vagrant_test'
	. .exports && aws ec2 detach-volume --volume-id `cat .volume_id`
	sleep 60
	. .exports && aws ec2 delete-volume --volume-id `cat .volume_id`

installdeps:
	mkdir -p modules
	bundle exec librarian-puppet install --path=./modules

pkg:
	puppet module build

debug:
	VAGRANT_LOG=DEBUG vagrant provision

.PHONY: default install debug pkg instance volume clean install cleanebs
