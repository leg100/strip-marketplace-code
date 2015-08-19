# strip-marketplace-code

A script to effectively strip the marketplace code from an AMI. Read about the problem here:

https://www.caseylabs.com/remove-the-aws-marketplace-code-from-a-centos-ami/

This script automates the steps described in that article.

To run:

```
./run.sh <marketplace-ami-id>
```

Which'll:
* launch an instance, attach an 8gb empty vol
* make an xfs filesystem on that vol (for CentOS v7; you'll probably want to change for other OSs)
* do a raw copy of the image onto the vol
* shutdown instance, detach volumes
* attach new vol as the root vol
* create image from the instance.
* spit out a new ami id
