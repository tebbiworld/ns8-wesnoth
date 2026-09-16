#!/bin/bash

#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

images=()
repobase="${REPOBASE:-ghcr.io/tebbiworld}"
reponame="wesnoth"

# wesnothd is built from the official Battle for Wesnoth source tag (server
# only, no game data). The pinned reference below is what the auto-release
# workflow bumps when a newer stable tag (even minor: 1.18.x, 1.20.x, ...)
# appears on GitHub.
wesnoth_ref="github.com/wesnoth/wesnoth:1.18.8"
wesnoth_version="${wesnoth_ref##*:}"

# Runtime image, tagged with the module version like the module image itself;
# exposed to the unit as ${WESNOTH_SERVER_IMAGE} through org.nethserver.images.
server_image="${repobase}/wesnoth-server:${IMAGETAG:-latest}"

echo "Build the wesnothd ${wesnoth_version} server image..."
podman build --force-rm --build-arg "WESNOTH_VERSION=${wesnoth_version}" -t "${server_image}" -f server/Containerfile server/
podman tag "${server_image}" "${repobase}/wesnoth-server"
images+=("${repobase}/wesnoth-server")

runtime_images=(
    "${server_image}"
)

container=$(buildah from scratch)

if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-wesnoth; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-wesnoth -v "${PWD}:/usr/src:Z" docker.io/library/node:24.16.0-slim
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-wesnoth \
    sh -c "yarn install && yarn build"

buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# node:fwadm: the game port is opened on the node firewall as a public
# service named after the instance. No Traefik route (raw TCP game
# protocol), no core port allocation: the port is chosen in the settings.
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=node:fwadm" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${runtime_images[*]}" \
    "${container}"
buildah commit "${container}" "${repobase}/${reponame}"

images+=("${repobase}/${reponame}")

if [[ -n "${CI}" ]]; then
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    printf "Publish the images with:\n\n"
    printf "  buildah push %s docker://%s\n" "${server_image,,}" "${server_image,,}"
    printf "  buildah push %s docker://%s:%s\n" "${repobase,,}/${reponame,,}" "${repobase,,}/${reponame,,}" "${IMAGETAG:-latest}"
    printf "\n"
fi
