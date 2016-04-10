#!/bin/bash
# This is to converting aggregation results of ES index top50 to top50 table

set -ue

ORIG_FILE=${1:-orig}

[[ -f $ORIG_FILE ]] || {
    echo "orig file not exist"
    exit 1
}

cat $ORIG_FILE | awk '{if (NR > 9) print $0}' | \
    grep -E "total|sum_other_doc_count" | \
    grep -v error_upper_bound | \
    awk -F '"|:|,' '{print $2, $4}' | \
    column -t > stats_total

cat $ORIG_FILE | awk '{if (NR > 9) print $0}' | \
    grep -E "key|doc_count" | \
    grep -v error_upper_bound | \
    grep -v sum_other | \
    sed 's/key//g; s/doc_count//g; s/\"//g; s/://g; s/,//g' | \
    xargs -L 2 | \
    column -t > stats_apps

total_count=$(head -1 stats_total | awk '{print $2}')

cat stats_total stats_apps | column -t | \
    awk -v total=$total_count '{printf "%s %s %.2f%%\n", $1, $2, $2*100/total}' | \
    column -t | tee top50
