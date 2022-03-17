#
# Common utils functions


function wlog {
    if [[ $# -eq 1 ]]; then
        echo $1
    else
        echo "${1}: ${2}"
    fi
}

function raise {
    wlog "ERROR" "${1}"
    exit 1
}
