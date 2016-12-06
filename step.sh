#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/libs/messages.sh"

if [ ! -d "$auth_token" ]; then
  msg_error "Auth token not found"
	exit 1
fi

if [ ! -d "$reviewed_key" ]; then
  msg_warn "Review comment key defaulted to 'code review ok'"
	$reviewed_key="code review ok"
fi



msg_info "Installing Octikit"
gem install octokit

msg_info "Executing script"
ruby "$SCRIPT_DIR/step.rb"
exit $?
