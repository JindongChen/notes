#!/bin/bash

set -o errexit
set -o pipefail

declare -i LONG_MAX=9223372036854775807
declare -i LONG_MIN=-9223372036854775808
readonly re='^-?[0-9]+([.][0-9]+)?$'

function usage
{
    echo "Usage:"
    echo "  $0 -q SQL_query -d database [-w warn] [-c crit] [-H host]"
    echo "      [-P port] [-u user] [-p password] [-m metric]"
    echo "Options:"
    echo "  -h, --help"
    echo "      Print detailed help screen"
    echo "  -q, --query STRING"
    echo "      SQL query to influxdb. Only second column in first row will be"
    echo "      read, and the result from the query should be numeric."
    echo "  -d, --database STRING"
    echo "      Influxdb database name"
    echo "  -w, --warning RANGE"
    echo "      Warning range (format: start:end). Alert if outside this range"
    echo "  -c, --critical RANGE"
    echo "      Critical range (format: start:end). Critical if outside this range"
    echo "  -H, --hostname hostname"
    echo "      Hostname or ip address of influxdb (default: 127.0.0.1)"
    echo "  -P, --port INTEGER"
    echo "      Influxdb port number (default: 8086)"
    echo "  -u, --user STRING"
    echo "      Influxdb username (default: anonymous)"
    echo "  -p, --password STRING"
    echo "      Influxdb password (default: anonymous)"
    echo "  -m, --metric STRING"
    echo "      Metric name (default: influxdb query result)"
}

while [[ $# -gt 0 ]]
do
key="$1"

    case $key in
    -h|--help)
    usage
    exit 0
    ;;
    -q|--query)
    QUERY="$2"
    shift
    ;;
    -w|--warning)
    WRANGE="$2"
    shift
    ;;
    -c|--critical)
    CRANGE="$2"
    shift
    ;;
    -H|--hostname)
    IHOSTNAME="$2"
    shift
    ;;
    -P|--port)
    IPORT="$2"
    shift
    ;;
    -u|--user)
    IUSER="$2"
    shift
    ;;
    -p|--password)
    IPASSWORD="$2"
    shift
    ;;
    -d|--database)
    IDATABASE="$2"
    shift
    ;;
    -m|--metric)
    METRIC="$2"
    shift
    ;;
    *)  # unknown option
    usage
    exit 1
    ;;
esac
shift # past argument or value
done

[[ "${QUERY:-unset}" != "unset" ]] || {
    echo "Query string is required."
    usage
    exit 1
}

[[ "${WRANGE:-unset}" != "unset" ]] || {
    WRANGE="$LONG_MIN:$LONG_MAX"
}

[[ "$WRANGE" == *":"* ]] || {
    echo "Warning range should contain ':'"
    usage
    exit 1
}

WSTART=$(echo $WRANGE | cut -d ':' -f 1)
WEND=$(echo $WRANGE | cut -d ':' -f 2)

[[ "${CRANGE:-unset}" != "unset" ]] || {
    CRANGE="$LONG_MIN:$LONG_MAX"
}

[[ "$CRANGE" == *":"* ]] || {
    echo "Critical range should contain ':'"
    usage
    exit 1
}

CSTART=$(echo $CRANGE | cut -d ':' -f 1)
CEND=$(echo $CRANGE | cut -d ':' -f 2)

[[ "${IHOSTNAME:-unset}" != "unset" ]] || {
    IHOSTNAME=127.0.0.1
}

[[ "${IPORT:-unset}" != "unset" ]] || {
    IPORT=8086
}

[[ "${IUSER:-unset}" != "unset" ]] || {
    IUSER="anonymous"
}

[[ "${IPASSWORD:-unset}" != "unset" ]] || {
    IPASSWORD="anonymous"
}

[[ "${IDATABASE:-unset}" != "unset" ]] || {
    echo "Influxdb database is required."
    usage
    exit 1
}

[[ "${METRIC:-unset}" != "unset" ]] || {
    METRIC="influxdb query result"
}

RESULT=$(curl -s -GET \
                    "http://${IHOSTNAME}:${IPORT}/query?pretty=true" \
                    -u ${IUSER}:${IPASSWORD} \
                    --data-urlencode "db=${IDATABASE}" \
                    --data-urlencode "q=${QUERY}" \
                    | awk 'NR == 14' | awk '{print $1}')


if ! [[ $RESULT =~ $re ]] ; then
    echo "QUERY CRITICAL - $METRIC is not a number."
    exit 2
fi

if (( CEND < RESULT || RESULT < CSTART )); then
    echo "QUERY CRITICAL - $METRIC is ${RESULT}."
    exit 2
elif (( WEND < RESULT || RESULT < WSTART )); then
    echo "QUERY WARNING - $METRIC is ${RESULT}."
    exit 1
else
    echo "QUERY OK - $METRIC is ${RESULT}."
    exit 0
fi
