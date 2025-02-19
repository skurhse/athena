#!/usr/bin/env bash

for component in $(find src/components/ -maxdepth 2 -type f -name shard.yml | xargs -I{} dirname {} | sort); do
  git diff --quiet --exit-code $BASE_SHA $GITHUB_SHA -- $component
  HAS_COMPONENT_CHANGED=$?
  if [[ $GITHUB_EVENT_NAME != 'pull_request' || $HAS_COMPONENT_CHANGED == 1 ]]; then
    echo "::group::$component"
    crystal spec $component/spec --order random --error-on-warnings --exclude-warnings $component/spec || exit 1
    echo "::endgroup::"
  fi
done
