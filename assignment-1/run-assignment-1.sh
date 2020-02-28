#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

ARGS_VALID=0 # default true
REGION='us-east-1' # localstack region

POSITIONAL=()
while [[ $# -gt 0 ]]; do
  key="$1"

  case $key in
      -s|--stack-name)
      STACK_NAME="$2"
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

  if [ $ARGS_VALID != '0' ]; then
    exit_script $ARGS_VALID
  fi
}

function build_docker_image {
  docker build ${DIR}/scripts > /dev/null
  DOCKER_IMAGE=$(docker images | awk '{print $3}' | awk 'NR==2')
  echo $DOCKER_IMAGE
}

# because all state from localstack will be lost, we need to clean workspace
function clean_tf_workspace {
  cd ${DIR}/terraform/solutions
  echo "Cleaning TF workspace"
  if [ -f .terraform ]; then
    echo "Removing .terraform"
    rm -rf .terraform
  fi

  if [ -f terraform.tfstate ]; then
    echo "Removing terraform.tfstate"
    rm terraform.tfstate
  fi

  if [ -f terraform.tfstate.backup ]; then
    echo "Removing terraform.tfstate.backup"
    rm terraform.tfstate.back
  fi
}

function deploy_terraform_infra {
  cd ${DIR}/terraform/solutions
  clean_tf_workspace
  terraform init
  terraform apply -auto-approve -var stack_name=${STACK_NAME} -var region=${REGION}
}

function get_terraform_output {
  OUTPUT_PARAM=$1
  cd ${DIR}/terraform/solutions
  terraform output ${OUTPUT_PARAM}
}

function run_random_streamer {
  echo "Building docker image"
  KINESIS_STREAM=$(get_terraform_output kinesis_stream_name)
  docker run -it --network="host" $(build_docker_image) --kinesis-stream ${KINESIS_STREAM} --region ${REGION}
}

function provision_localstack {
  # annoyingly this isn't possible according to the docs
  #localstack start &

  curl localhost:4572 > /dev/null
  s3_service_status=$?
  curl localhost:4573 > /dev/null
  firehose_service_status=$?

  while [ $s3_service_status != 0 ] || [ $firehose_service_status != 0 ]; do
    echo "Localstack not yet provisioned. Waiting..."
    sleep 10;
    curl localhost:4572
    s3_service_status=$?
    curl localhost:4573
    firehose_service_status=$?
  done

  sleep 10; # just a little extra time for localstack
}

check_args
provision_localstack
deploy_terraform_infra
run_random_streamer

if [ ! -f outputs ]; then
  echo "Removing terraform.tfstate"
  mkdir ${DIR}/outputs
fi

echo "Getting and showing data sent to S3 bucket"
aws --endpoint-url http://localhost:4572 s3 sync s3://$(get_terraform_output bucket_name) ${DIR}/outputs/.

docker kill localstack_main
