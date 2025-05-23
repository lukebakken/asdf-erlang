#!/bin/sh

# By setting CI=true, this means that `kerl version` will not echo the
# following output if `tput sgr0` fails within the `kerl` script:
#
# "Colorization disabled as 'tput' (via 'ncurses') seems to be
#  unavailable."
#
# `tput sgr0` can fail if `kerl` is run via `asdf`, for instance.
#
# This is important, because the version check in this script depends on
# the output simply being a version string, like `4.3.0`. If the above
# text is output, the version check fails in ensure_kerl_installed, and
# kerl is _always_ downloaded.
export HOME='/home/lbakken'
export CI='true'
export KERL_VERSION="${ASDF_KERL_VERSION:-4.3.0}"

handle_failure() {
    function=$1
    error_message=$2
    $function && exit_code=$? || exit_code=$?

    if [ "$exit_code" -ne 0 ]; then
        printf "%s\\n" "$error_message" 1>&2
    fi

    return "$exit_code"
}

ensure_kerl_setup() {
    handle_failure set_kerl_env 'Failed to set kerl environment'
    handle_failure ensure_kerl_installed 'Failed to install kerl'
    handle_failure update_available_versions 'Failed to update available versions'
}

ensure_kerl_installed() {
    if [ ! -f "$(kerl_path)" ]; then
        download_kerl
    elif [ "$("$(kerl_path)" version)" != "$KERL_VERSION" ]; then
        # If the kerl file already exists and the version does not match, remove
        # it and download the correct version
        rm "$(kerl_path)"
        download_kerl
    fi
}

download_kerl() {
    # Print to stderr so asdf doesn't assume this string is a list of versions
    printf "Downloading kerl...\\n" >&2

    kerl_url="https://raw.githubusercontent.com/lukebakken/kerl/refs/heads/lrb-master/kerl"
    # kerl_url="https://raw.githubusercontent.com/kerl/kerl/${KERL_VERSION}/kerl"

    curl -Lo "$(kerl_path)" "$kerl_url"
    chmod +x "$(kerl_path)"

    unset kerl_url
}

kerl_path() {
    printf "%s\\n" "$(dirname "$(dirname "$0")")/kerl"
}

set_kerl_env() {
    kerl_home="$(dirname "$(dirname "$0")")/kerl-home"
    mkdir -p "$kerl_home"
    export KERL_BASE_DIR="$kerl_home"
    export KERL_BUILD_BACKEND="git"
    export KERL_CONFIG="$kerl_home/.kerlrc"
    export KERL_DOWNLOAD_DIR="${ASDF_DOWNLOAD_PATH:-}"
    unset kerl_home
}

update_available_versions() {
    "$(kerl_path)" update releases >/dev/null
}
