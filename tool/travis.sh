#!/bin/bash

# Fast fail the script on failures.
set -xe

dartanalyzer --fatal-warnings lib test

pub run test
# pub run test -p vm,chrome
# pub run build_runner test -- -p vm,chrome