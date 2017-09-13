#!/bin/bash

THIS_SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

set -e
ls -l

cd $THIS_SCRIPT_DIR && bundle install
bundle exec ruby "$THIS_SCRIPT_DIR/step.rb"
exit $?