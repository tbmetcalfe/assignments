# Assignment 1

This document shows how to execute the scripts and tools utilised for fulfilling requirement as outlined in the assignment document.

## Installing the dependencies

- localstack
- aws
- terraform
- docker

## Running the scripts

### The automated way

1. Start localstack by running `localstack start`
2. Run from the assignment-1 directory `bash ./run-assignment-1.sh`

#### Script details

1. Waits for connectivity to localstack - assumed to be running on localhost
2. Cleans the terraform workspace and deploys the terraform infrastructure
3. Builds the docker image with the python source code and dependencies
4. Runs random data generator against the created kinesis stream.
5. Gets the files put onto S3 bucket into the host machine in the `./outputs` directory
6. Kills the localstack process.

## Maintainer
Tristan Metcalfe <tbmetcalfe1@gmail.com>
