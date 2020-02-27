# Assignment 1

This document shows how to execute the scripts and tools utilised for fulfilling requirement as outlined in the assignment document.

## Installing the dependencies

- aws
- docker

## Running the scripts

### The automated way

1. Start localstack by running `localstack start`
2. Run from the assignment-2 directory `bash ./run-assignment-2.sh`

#### Script details

1. Creates the Cloudformation stack
  - Contains one VPC with one subnet and an autoscaling group with 10 instances (default)
2. Waits for the stack to finish provisioning
3. Runs the instance recycler `terminator.py`
4. Tears down the Cloudformation stack.

#### Notes

- Note that instances are set to t2.micro so should be free, or at least reasonable.

## Maintainer
Tristan Metcalfe <tbmetcalfe1@gmail.com>
