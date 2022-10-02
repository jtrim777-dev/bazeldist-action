#!/usr/bin/env bash

set -ex

# $1 = tag
# $2 = version_file
# $3 = version_sub_files (comma-sep)
# $4 = bazel_targets (comma-sep)
# $5 = gh_email
# $6 = gh_name
# $7 = gh_token
# $8 = dist_user
# $9 = dist_pwd

J1=$(echo -en "$3" | jq -Rc 'split(",")')
J2=$(echo -en "$4" | jq -Rc 'split(",")')
J3=$(jq -nc \
        --arg gh_email "$5" \
        --arg gh_name "$6" \
        --arg gh_token "$7" \
        --arg dist_user "$8" \
        --arg dist_pwd "$9" \
        '$ARGS.named')
INPUT=$(jq -nc \
            --arg tag "$1" \
            --argjson auth "$J3" \
            --argjson version_sub_files "$J1" \
            --argjson bazel_targets "$J2" \
            --arg version_file "$2" \
            '$ARGS.named')
echo -e "$INPUT" > /tmp/input.json

# INPUT FORMAT:
# {"tag": "v0.1.9", "auth": {"gh_email": "...", "gh_name": "...", "gh_token": "...",
#    "dist_user": "...", "dist_pwd": "..."}, "version_sub_files": [...], "version_file": "VERSION",
#    "bazel_targets": ["..."]}

export BAZELDIST_USERNAME=$(jq -r '.auth.dist_user' /tmp/input.json)
export BAZELDIST_PASSWORD=$(jq -r '.auth.dist_pwd' /tmp/input.json)
export GITHUB_ACTOR=$(jq -r '.auth.gh_name' /tmp/input.json)
export GITHUB_EMAIL=$(jq -r '.auth.gh_email' /tmp/input.json)
export GITHUB_TOKEN=$(jq -r '.auth.gh_token' /tmp/input.json)

VERSION=$(echo "$1" | sed -E 's|v||g')
ISNAP=$(echo -n "-$XVZN" | tr -dc '-' | awk '{ print length; }')
RELEASE_TYPE=$([ $ISNAP -eq 1 ] && echo -n "release" || echo -n "snapshot")

bazel info

OLDVZN=$(cat "$2")

jq -cr '.version_sub_files[]' /tmp/input.json | while read subfile; do
    sed -i "s/$OLDVZN/$VERSION/g" "$subfile"
done
sed -i "s/$OLDVZN/$VERSION/g" "$2"

jq -cr '.bazel_targets[]' /tmp/input.json | while read btarget; do
    bazel run $btarget -- "$RELEASE_TYPE"
done

echo "::set-output name=version::$VERSION"
echo "::set-output name=release_type::$RELEASE_TYPE"

