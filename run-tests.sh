#!/bin/bash

# Selectively run tests for this repo, based on what has changed
# in a commit. Runs short tests for the whole repo, and full tests
# for changed directories.

set -e

if [[ $1 == "" ]]; then
  echo >&2 "usage: $0 COMMIT"
  exit 1
fi

# Files or directories that cause all tests to run if modified.
declare -A run_all
run_all=([.travis.yml]=1 [run-tests.sh]=1 [internal]=1)

dryrun=false
if [[ $1 == "-n" ]]; then
  dryrun=true
  shift
fi

function run {
  if $dryrun; then
    echo $*
  else
    (set -x; $*)
  fi
}


# Get all the top-level files and directories that have changed in this commit.
diffs=$(git diff-tree --no-commit-id --name-only $1)

# See if any require a full test. If so, run the test and exit.
for f in $diffs; do
  if [[ ${run_all[$f]} == 1 ]]; then
    run go test -race -v cloud.google.com/go/...
    exit
  fi
done

# Otherwise, first run short tests on the whole repo.
run go test -short -race -v cloud.google.com/go/...

# Then run full tests only on the changed directories.
for f in $diffs; do
  if [[ -d $f ]]; then
    run go test -race -v cloud.google.com/go/$f/...
  fi
done
  

  
