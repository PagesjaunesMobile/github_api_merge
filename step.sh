#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set +e
set
which ruby
ruby -v
gem -v
gem install octokit
set -e
ruby "$THIS_SCRIPT_DIR/step.rb"
exit $?
