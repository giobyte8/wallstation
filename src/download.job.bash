#!/bin/bash
#
# Validate config file and permissions over specified folders
# and initiates download of each source

# ref: https://stackoverflow.com/a/4774063/3211029
HERE="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
APP_ROOT="$(cd "$HERE/.." ; pwd -P)"

CONFIG_DIR="${APP_ROOT}/config"
CONFIG_FILE="${CONFIG_DIR}/config.yml"
GCONFIG_FILE="${CONFIG_DIR}/gallery-dl.conf.json"

URL_REGEX='^(https?)://[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]\.[-A-Za-z0-9\+&@#/%?=~_|!:,.;]*[-A-Za-z0-9\+&@#/%=~_|]$'

source "$HERE/common.bash"


function validate_writable_path {
    if [ ! -d "$1" ]; then
        raise "Path does not exists: $1"
    fi

    if [ ! -w "${1}" ]; then
        raise "Path is not writable: $1"
    fi
}

function validate_wallpapers_source {

    # Validate url format
    # TODO Should also validate url domain is supported?
    url="$(echo "$1" | yq '.url')"
    if [[ ! "$url" =~ $URL_REGEX ]]; then
        raise "Invalid url: $url"
    fi

    # Validate destination is a valid directory name
    des="$(echo "$1" | yq '.destination')"
    des="${WALLPAPERS_ROOT}/${des}"
    mkdir -p "$des"
    validate_writable_path "$des"
}

function load_config {

    # Validate config file
    if [ ! -f "${CONFIG_FILE}" ]; then
        raise "Invalid config file: ${CONFIG_FILE}"
    fi

    # Verify gallery config file existence
    if [ ! -f "${GCONFIG_FILE}" ]; then
        raise "Invalid config file: ${GCONFIG_FILE}"
    fi

    # Use jq to read config
    APPDATA=$(yq '.appdata' "$CONFIG_FILE")
    WALLPAPERS_ROOT=$(yq '.wallpapers_root' "$CONFIG_FILE")

    # Validate config values
    validate_writable_path "$APPDATA"
    validate_writable_path "${WALLPAPERS_ROOT}"

    # TODO Validate output resolutions

    # Validate source length
    SOURCES_LENGTH=$(yq '.sources | length' "$CONFIG_FILE")
    if [ $SOURCES_LENGTH -eq 0 ]; then
        raise "Add at least one source to config file"
    fi

    # Validate each source values
    for ((i = 0; i < $SOURCES_LENGTH; i++))
    do
        SOURCE="$(i=$i yq '.sources.[env(i)]' "$CONFIG_FILE")"
        validate_wallpapers_source "$SOURCE"
    done
}

function download_sources {
    DARCHIVE="${APPDATA}/wallstation.sqlite"

    for ((i = 0; i < $SOURCES_LENGTH; i++))
    do
        SOURCE="$(i=$i yq '.sources.[env(i)]' "$CONFIG_FILE")"
        url="$(echo "$SOURCE" | yq '.url')"
        des="$(echo "$SOURCE" | yq '.destination')"
        des="${WALLPAPERS_ROOT}/${des}"

        echo
        echo "Downloading: ${url}"
        echo "       Into: ${des}"

        gallery-dl -D "${des}" --download-archive "${DARCHIVE}" -c "${GCONFIG_FILE}" "${url}"
    done
}

load_config
download_sources
