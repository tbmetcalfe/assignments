#!/bin/bash

ARGS_VALID=0 # default true
REGION='eu-west-1' # currently only supports this region

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
      -s|--stack-name)
      STACK_NAME="$2"
      shift # past argument
      shift # past value
      ;;
      -a|--asg-name)
      ASG_NAME="$2"
      shift # past argument
      shift # past value
      ;;
      *)
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
  esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

function check_arg {
  ARG_NAME=$1
  ARG_VALUE=$2

  if [ "$ARG_VALUE" == '' ]; then
    echo "$ARG_NAME is a required argument. Use --help for more info"
    ARGS_VALID=1
  fi
}

function check_args {
  check_arg '--stack-name' ${STACK_NAME}
  check_arg '--asg-name' ${ASG_NAME}

  if [ $ARGS_VALID != '0' ]; then
    exit $ARGS_VALID
  fi
}

function build_docker_image {
  docker build ${DIR}/scripts > /dev/null
  DOCKER_IMAGE=$(docker images | awk '{print $3}' | awk 'NR==2')
  echo $DOCKER_IMAGE
}

check_args
aws cloudformation create-stack --stack-name ${STACK_NAME} \
                                --template-body file://${DIR}/cf-templates/autoscaling-group.yaml \
                                --parameters ParameterKey=ASGName,ParameterValue=${ASG_NAME}
# wait until stack has finished provisioning.
echo "Waiting for stack ${STACK_NAME} to finish creating..."
aws cloudformation wait stack-create-complete --stack-name ${STACK_NAME}

docker run -it --network="host" -e AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID}" -e AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY}" $(build_docker_image) --asg-name ${ASG_NAME} --region ${REGION}

aws cloudformation delete-stack --stack-name ${STACK_NAME}
