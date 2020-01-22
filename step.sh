#!/bin/bash

set +e

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$THIS_SCRIPT_DIR/libs/messages.sh"

msg_info "auth_token: $auth_token"
msg_info "delete_branch: $delete_branch"

if [ -z "$auth_token" ]; then
  msg_error "auth_token not found"
	exit 1
fi

cd $THIS_SCRIPT_DIR && gem install octokit
msg_info "Installing Octokit"
cd $THIS_SCRIPT_DIR && bundle install
set -e
msg_info "Executing script"
ruby "$THIS_SCRIPT_DIR/step.rb"
exit $?
