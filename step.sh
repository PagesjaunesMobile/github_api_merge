#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/libs/messages.sh"

msg_info "auth_token: $auth_token"
msg_info "reviewed_key: $reviewed_key"

if [ -z "$auth_token" ]; then
  msg_error "auth_token not found"
	exit 1
fi

if [ -z "$reviewed_key" ]; then
  msg_warn "reviewed_key defaulted to 'code review ok'"
	reviewed_key="code review ok"
fi



msg_info "Installing Octikit"
gem install octokit

msg_info "Executing script"
ruby "$SCRIPT_DIR/step.rb"
exit $?
