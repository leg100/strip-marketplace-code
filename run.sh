#!/usr/bin/env bash

set -e

MARKETPLACE_AMI=$1
NEW_NAME=$2

# run marketplace instance with attached empty vol
# userdata commands will take care of copying the OS to the empty vol and then shutdown it down
RUN_OUT=$(aws ec2 run-instances --image-id $MARKETPLACE_AMI --cli-input-json file://run.json --user-data file://user-data)
INST_ID=$(echo $RUN_OUT | jq -r '.Instances[0].InstanceId')
echo launched $INST_ID

echo waiting for it to shutdown
while true; do
  STATE=$(aws ec2 describe-instance-status --include-all-instances --instance-ids $INST_ID | jq -r '.InstanceStatuses[0].InstanceState.Name')
  if [[ "$STATE" = "stopped" ]]; then
    break
  fi
  sleep 10
done

# get volume id's
MAPPINGS=$(aws ec2 describe-instances --instance-ids $INST_ID  | jq -r '.Reservations[0].Instances[0].BlockDeviceMappings')
MARKETPLACE_VOL=$(echo $MAPPINGS | jq -r 'map(select(.DeviceName == "/dev/sda1"))[0].Ebs.VolumeId')
NEW_VOL=$(echo $MAPPINGS | jq -r 'map(select(.DeviceName == "/dev/xvdj"))[0].Ebs.VolumeId')

for v in $MARKETPLACE_VOL $NEW_VOL; do
  echo detaching $v
  aws ec2 detach-volume --volume-id $v --instance-id $INST_ID

  while true; do
    STATE=$(aws ec2 describe-volumes --volume-id $v | jq -r '.Volumes[0].State')
    if [[ "$STATE" = "available" ]]; then
      break
    fi
    sleep 1
  done
done

echo re-attaching $NEW_VOL as root device
aws ec2 attach-volume --volume-id $NEW_VOL --instance-id $INST_ID --device /dev/sda1
while true; do
  STATE=$(aws ec2 describe-volumes --volume-id $NEW_VOL | jq -r '.Volumes[0].State')
  if [[ "$STATE" = "in-use" ]]; then
    break
  fi
  sleep 1
done

echo creating image with name $NEW_NAME
NEW_IMAGE=$(aws ec2 create-image --instance-id $INST_ID --name $NEW_NAME | jq -r '.ImageId')
while true; do
  STATE=$(aws ec2 describe-images --image-id $NEW_IMAGE | jq -r '.Images[0].State')
  if [[ "$STATE" = "available" ]]; then
    break
  fi
  sleep 1
done

echo 'done!'
