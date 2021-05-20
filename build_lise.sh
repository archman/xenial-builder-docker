#!/usr/bin/env bash

#
# 1. Build LISE++ Qt project --> source tarball --> patching
# 2. Bundle binary into a tarball
# 3. Create self-extractable script
# 4. Ship binary bundle for Debian packaging
#
# Usage: build_lise.sh --input <source_tarball> \
#                     --src-version <verion_number>
#                     [--ouptut <output_dir>] [-j,--jobs <njobs>]
#
BLD_IMAGE="tonyzhang/xenial-builder:3.0"


tmp_dir=$(mktemp -d -t XXXXXXXXXX)
set -Eeuo pipefail
trap cleanup SIGINT SIGTERM ERR EXIT

usage() {
    cat << EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-v] --i,--input param_value arg1 [arg2...]

Build and bundle LISE++ Qt project.

Available options:

-h, --help          Print this help and exit
-v, --verbose       Print script debug info
-i, --input         Path of the input source tarball
    --src-version   Version of the input source tarball
-o, --output        Output directory for generated artifacts
-j, --jobs          Pass to -j argument of make
EOF
    exit
}

setup_colors() {
  if [[ -t 2 ]] && [[ -z "${NO_COLOR-}" ]] && [[ "${TERM-}" != "dumb" ]]; then
    NOFORMAT='\033[0m' RED='\033[0;31m' GREEN='\033[0;32m' ORANGE='\033[0;33m' BLUE='\033[0;34m' PURPLE='\033[0;35m' CYAN='\033[0;36m' YELLOW='\033[1;33m'
  else
    NOFORMAT='' RED='' GREEN='' ORANGE='' BLUE='' PURPLE='' CYAN='' YELLOW=''
  fi
}

cleanup() {
    trap - SIGINT SIGTERM ERR EXIT
    # clean up
    rm -rf $tmp_dir
}

msg() {
    echo >&2 -e "${1-}"
}

die() {
    local msg=$1
    local code=${2-1}
    msg "$msg"
    exit "$code"
}

parse_params() {
    njobs=''
    input_src=''
    input_src_ver=''
    output_dir=$(pwd)

    while :; do
        case "${1-}" in
            -h | --help) usage ;;
            -v | --verbose) set -x ;;
            --no-color) NO_COLOR=1 ;;
            -i | --input)
                input_src="${2-}"
                shift
                ;;
            --src-version)
                input_src_ver="${2-}"
                shift
                ;;
            -o | --output)
                output_dir="${2-}"
                shift
                ;;
            -j | --jobs)
                njobs="${2-}"
                shift
                ;;
            -?*) die "Unknown option: $1" ;;
            *) break ;;
        esac
        shift
    done

    # args=("$@")

    [[ -z "${input_src-}" ]] && die "Missing required parameter: --input"
    [[ -z "${input_src_ver-}" ]] && die "Missing required parameter: --src-version"
    # [[ ${#args[@]} -eq 0 ]] && die "Missing script arguments"

    return 0
}

script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd -P)
parse_params "$@"
setup_colors

msg "${GREEN}Decompress source tarball ${input_src_ver}${NOFORMAT}"
tar xf ${input_src} -C $tmp_dir

# source patching: modifinication before building
# sed -i '/^bool startFrom/s/.*/bool startFromFrameWork = true;/' $tmp_dir/w_Main/main.cpp
#

msg "${GREEN}Start working...${NOFORMAT}"
docker run -v $tmp_dir:/appbuilder -it --rm \
    -u "$(id -u):$(id -g)" \
    ${BLD_IMAGE} \
    --version ${input_src_ver} \
    --jobs ${njobs}

[[ ! -e ${output_dir} ]] && mkdir -p ${output_dir}
cp $tmp_dir/*.{tar.bz2,run} ${output_dir}
