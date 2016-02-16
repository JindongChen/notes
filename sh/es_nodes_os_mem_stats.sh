#!/bin/bash

readonly LOGBOOK_ES_01_URL="http://logbook-es-01.xx.local"

function _es_nodes_os
{
    local es_url=${1:-$LOGBOOK_ES_01_URL}

    # "cluster_name" : "logbook",
    #     "name" : "data-172.20.87.28",
    #         "actual_free_in_bytes" : 227705470976,
    #         "actual_used_in_bytes" : 43046252544

    curl -s "$es_url/_nodes/stats/os?pretty" \
        | grep -v "cluster_name" \
        | grep -E "actual_used_in_bytes|actual_free_in_bytes|name" \
        | sed 's/[,:"]//g'
}

function _es_nodes_os_metrics
{
    local prefix="logbook.nodes.os"
    local tag="cluster=logbook-es-01"
    local time=$(date '+%s')
    local line
    local role
    local name
    local free_memory
    local used_memory

    _es_nodes_os | \
    while read -r line; do
        set -- $line

        [[ -n ${2:-} ]] || {
            echo "$time Unexpected output from /_nodes/stats API: '$line'" >&2
            continue
        }

        case "$1" in
            name*)
                name=$2
                case "$2" in
                    data*) role="data";;
                    gateway*) role="gateway";;
                    master*) role="master";;
                    *) role="?";;
                esac
                continue
                ;;
            actual_free_in_bytes*)
                free_memory=$2
                continue
                ;;
            actual_used_in_bytes*)
                used_memory=$2
                ;;
        esac

        echo "put ${prefix}.mem.free" "$time" "$free_memory" "$tag" "name=$name" "role=$role"
        echo "put ${prefix}.mem.used" "$time" "$used_memory" "$tag" "name=$name" "role=$role"
    done
}

_es_nodes_os_metrics
