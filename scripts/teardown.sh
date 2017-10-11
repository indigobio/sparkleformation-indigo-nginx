#!/bin/bash -e

run_if_yes () {
  cmd=$1
  echo -n "$cmd [Y/n]? "
  read response
  case $response in
    Y|y)
      eval $cmd
    ;;
    *)
     echo "skipping"
    ;;
  esac
}

# Tear down the stack
stack=$(aws cloudformation list-stacks --stack-status-filter CREATE_COMPLETE UPDATE_COMPLETE DELETE_FAILED \
  --query 'StackSummaries[].StackId' --output table | grep ${environment}-nginx-${AWS_DEFAULT_REGION} \
  | awk '{print $2}')

cmd="aws cloudformation delete-stack --stack-name $stack"
run_if_yes "$cmd"
