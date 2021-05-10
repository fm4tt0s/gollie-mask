#!/usr/bin/env bash
#
# author    : felipe mattos
# date      : May-10-2021
# version   : 0.1
#
# purpose   : convert csv (or other delimited) file into json
# remarks   : na
# require   : bash and common sense
#
# changelog
#

# ------ first things, first ------
# bail if not using bash - a lot to prevent the friendly fire
# need some additional checks here
if [[ -z "${BASH}" ]] || [[ "${BASH_VERSINFO[0]}" -lt 3 ]]; then
    echo "Aaaarrrrgggghhhh Ye Neeeeeed BAAAAASSSSH (bash 3+ required)" >&2 && exit 1
fi

function usage() {
    # what: if it ran you need help. shows script usage.
    echo ""
    echo "  Usage:"
    echo "      ${0} -d[alternative delimiter ',' - default is ';'] -f[file]"
    echo ""
    echo "      ** first line assumed as header **"
    echo ""
    echo "  Example:"
    echo "      ${0} -f file_to_process.csv"
    echo "      ${0} -d, -f file_to_process.csv"
    echo ""
    echo "  Supported CSV formats:"
    echo "      field1;field2"
    echo "      field1,field2"
    echo "      \"field1\",\"field2\"   * not recommended"
    echo ""
    exit 1    
}

function filecheck() {
    # very basic check of csv, bails if it's malformed
    # first check if delimiter exists, so dont mess it when its not default/not specified
    grep -qc "${_delimiter}" "${_file}" > /dev/null || return 1
    # assumes 1st line is header then check if other lines have same number of columns as header
    awk -F "${_delimiter}" 'NR==1{NCOLS=NF};NF!=NCOLS{exit 1}' < "${_file}" > /dev/null
}

function macheteit() {
    # transform delimited data to json
    # check for " (quotes) in the file, if it exists remove them all 
    # this might break, so try to avoid using quoted fields
    if grep -c \" "${_file}" > /dev/null; then
        tr -d \" < "${_file}" > "/tmp/${0}.$$$$$$"
        _file="/tmp/${0}.$$$$$$"
    fi

    local _json_fields && _json_fields=$(head -1 "${_file}")
    local _json_base="{ "
    local _json_ocount && _json_ocount=$(echo "${_json_fields//${_delimiter}/ }" | wc -w | bc)
    local _json_fcount=0

    # define base for fields - they can vary
    for i in ${_json_fields//${_delimiter}/ }; do
        [[ "${_json_ocount}" -ne 1 ]] && _json_base="${_json_base}\"${i}\" : \"_FIELD_${_json_fcount}\","
        [[ "${_json_ocount}" -eq 1 ]] && _json_base="${_json_base}\"${i}\" : \"_FIELD_${_json_fcount}\" }"
        ((_json_ocount--))
        ((_json_fcount++))
    done

    # create an array out of all lines in result file
    IFS=$'\n' read -d '' -r -a LINE < <(tail -n +2 "${_file}")

    # get a pointer so we know when we're in the last element of array
    _json_ocount="${#LINE[@]}" && _json_ocount=$((_json_ocount - 1))

    for i in "${LINE[@]}"; do
        _json_object="${_json_base}"
        IFS="${_delimiter}" read -d '' -r -a LINE_ < <(echo "${i}")
        for ((j=0;j<${#LINE_[@]};j++)); do
            _clean_data=$(echo "${LINE_[$j]}" | tr -d '$')
            _json_object="${_json_object//_FIELD_${j}/${_clean_data}}"
        done
        [[ "${_json_ocount}" -ne 0 ]] && _json_object="${_json_object},"
        ((_json_ocount--))
        _json_file="${_json_file}${_json_object}"
    done
    _json_file="[   ${_json_file}   ]"
    # show json
    echo "${_json_file}"
}

_delimiter=";"
# parse command line
[[ "${#}" -eq 0 ]] && usage
while getopts ":d:f:" _cmd_line; do
    case "${_cmd_line}" in
        d) 
            _delimiter="${OPTARG}"
            ! [[ "${_delimiter}" =~ ^(,|;)$ ]] && echo "Ye Run A Rig, Lessie! Aint no piece for ${_delimiter} as delimiter" && exit 1
            ;;
        f) 
            _file="${OPTARG}"
            [[ -z "${_file}" ]] && usage
            ;;
        :|\?|\*)
            usage
            ;;
    esac
done

# check if file exists and it's readable
! [[ -r "${_file}" ]] && echo "It Aint Nay Bucko! Therez a Bounty for it! ${_file} not found." && exit 1

# validate the file and transform it
if ! filecheck; then
    echo "Avast Ye Mate! ${_file} is barnacle-covered and malformed."
    exit 1
else
    macheteit
fi