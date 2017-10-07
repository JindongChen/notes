#!/bin/bash

readonly REGISTRY=jind
readonly NAMESPACE=data-science
readonly FINAL_NAME=notebook-$(date +%Y%m%d%H%M%S)
readonly IMAGE_NAME=${REGISTRY}/${NAMESPACE}/${FINAL_NAME}
readonly IMAGE_TAG=latest
readonly IMAGE="${IMAGE_NAME}:${IMAGE_TAG}"
readonly DOCKER_BUILD_OPTIONS="--no-cache"

docker build ${DOCKER_BUILD_OPTIONS} -t ${IMAGE} .
docker images | grep --color -E "^${IMAGE_NAME} +${IMAGE_TAG} "
echo IMAGE_NAME=${IMAGE_NAME} > build-result.properties
