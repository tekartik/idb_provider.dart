#!/bin/bash

# Fast fail the script on failures.
set -e

dartanalyzer --fatal-warnings \
  lib/provider.dart \
  lib/record_provider.dart \

pub run test -p vm,chrome