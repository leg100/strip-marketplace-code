# strip-marketplace-code

WARNING: I haven't got this to work, the CentOS image it produces seems to be corrupted (not surprisingly, given it does a raw copy of a mounted root device)

A script to effectively strip the marketplace code from an AMI. Read about the problem here:

https://www.caseylabs.com/remove-the-aws-marketplace-code-from-a-centos-ami/

This script automates the steps described in that article. You'll need [awscli](https://aws.amazon.com/cli/) and [jq](https://stedolan.github.io/jq/).

To run:

```
./run.sh <marketplace-ami-id> <name-of-new-ami>
```

Which'll:
* launch an instance, attach an 8gb empty vol
* make an xfs filesystem on that vol (for CentOS v7; you'll probably want to change for other OSs)
* do a raw copy of the image onto the vol
* shutdown instance, detach volumes
* attach new vol as the root vol
* create image from the instance.
* spit out a new ami id

Note this'll take a bit of time.
