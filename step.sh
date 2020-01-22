#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e
ruby -v
gem -v
gem install octokit
ruby "$THIS_SCRIPT_DIR/step.rb"
exit $?
