#!/usr/bin/env bash

set -euo pipefail

if [ ! -s /dev/stdin ]; then
    echo "error: payload stdin is empty"
    exit 1
fi

script="${1:-}"

if [ -z "${script}" ]; then
    echo "error: please provide script in first argument [in, out, check]"
    exit 1
fi

docker build -t concourse-git-bitbucket-pr-resource:dev .
docker run --rm -i -v "${PWD}/.tmp:/tmp/resource" concourse-git-bitbucket-pr-resource:dev \
    bash "${BASH_OPTS:-+x}" "/opt/resource/${script}" "/tmp/resource" <<< "$(cat)"
