#!/bin/bash

set +e

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_SCRIPT_DIR/libs/messages.sh"

msg_info "auth_token: $AUTH_TOKEN"
msg_info "delete_branch: $delete_branch"

if [ -z "$auth_token" ]; then
  msg_error "auth_token not found"
	exit 1
fi

cd $THIS_SCRIPT_DIR && gem install gitlab
msg_info "Installing api client"

set -e
ruby -v
msg_info "Executing script"
ruby "$THIS_SCRIPT_DIR/step.rb"
exit $?
