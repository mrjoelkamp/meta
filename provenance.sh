#!/bin/bash

export BUILD_ID="d3744c8043a6688aefdff757fc4c6ec66e03ae85c7fa7267d0ee848054cf72cc"
github='{"run_attempt":"1","run_id":"10780651714","server_url":"https://github.com","ref":"refs/heads/main","sha":"11d1f3b6c0efade1b907d0ff3ab41e960787fbf4","repository_owner_id":"2976326","repository_id":"712982891","event_name":"workflow_dispatch","event":{"inputs":{"bashbrewArch":"amd64","buildId":"d3744c8043a6688aefdff757fc4c6ec66e03ae85c7fa7267d0ee848054cf72cc","firstTag":"backdrop:1.26.1"}},"repository":"mrjoelkamp/gha-test","workflow_ref":"mrjoelkamp/gha-test/.github/workflows/test.yml@refs/heads/main","workflow_sha":"11d1f3b6c0efade1b907d0ff3ab41e960787fbf4"}'

image-digest() {
    local dir="$1"
    local manifest
    manifest="$dir/blobs/$(jq -r '.manifests[0].digest | sub(":"; "/")' "$dir/index.json")" || return "$?"
    jq -s '
        if length != 1 then
          error("unexpected image index document count: " + length)
        else .[0] end
        | if .schemaVersion != 2 then
          error("unsupported schemaVersion: " + .schemaVersion)
        else . end
        | if .mediaType != "application/vnd.oci.image.index.v1+json" then
          error("unsupported image index mediaType: " + .mediaType)
        else . end
    ' "$manifest" >> /dev/null || return "$?"
    jq -r '
      .manifests[] | select(.platform.architecture == "amd64" and .platform.os == "linux") | .digest
    ' "$manifest" || return "$?"
}

digest=$(image-digest temp)

jq -L.scripts --arg digest ${digest#sha256:} --argjson context $github \
            '
              include "provenance";
              .[env.BUILD_ID]
              | .provenance = provenance($digest; $context)
              | .provenance
            ' builds.json
