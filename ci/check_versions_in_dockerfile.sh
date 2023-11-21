#! /bin/sh

# This script is meant to be run in the CI, it checks the versions of the
# packages in the Dockerfile are the same as the ones in .tool-versions. If
# they are not, it exits with an error code.

erlang_version_docker=$(grep 'ARG ERLANG_VERSION' Dockerfile | cut -d '=' -f 2)
gleam_version_docker=$(grep 'ARG GLEAM_VERSION' Dockerfile | cut -d '=' -f 2)

erlang_version_asdf=$(grep 'erlang' .tool-versions | cut -d ' ' -f 2)
gleam_version_asdf=$(grep 'gleam' .tool-versions | cut -d ' ' -f 2)

exit_code=0

must_be_same() {
    if [ "$1" != "$2" ]; then
        echo "$3 version mismatch: docker=$1 asdf=$2"
        exit_code=1
    fi
}

must_be_same "$erlang_version_docker" "$erlang_version_asdf" "Erlang"
must_be_same "$gleam_version_docker" "$gleam_version_asdf" "Gleam"

exit $exit_code
