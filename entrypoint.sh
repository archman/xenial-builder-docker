#!/bin/bash

set -Eeuo pipefail
trap _fallback SIGINT SIGTERM ERR EXIT
trap _on_exit EXIT

_fallback() {
    trap - SIGINT SIGTERM ERR
    echo "An error occurred for auto-build. Falling back to interactive shell..."
    if [ -t 0 ]; then
        /bin/bash
    else
        echo "Not running interactively. Exiting..."
        exit 1
    fi
}

_on_exit() {
    trap - EXIT
    echo "Cleaning up before exiting..."
    rm -rf ${dist_dir}
    make distclean
}

QT_DEPLOYER_OPTS="-bundle-non-qt-libs -no-translations"
MAKESELF_OPTS="--notemp --nox11"
MAXNJOBS=$(cat /proc/cpuinfo | grep processor | wc -l)

njobs=''
ver=''
pro_file=''
execs=''
dist_dir=''
app_name=''
while :; do
    case "${1-}" in
        -j | --jobs)
            njobs="${2-}"
            shift
            ;;
        -p | --project)
            pro_file="${2-}"
            shift
            ;;
        -e | --executables)
            execs="${2-}"
            shift
            ;;
        --app)
            app_name="${2-}"
            shift
            ;;
        -d | --dist)
            dist_dir="${2-}"
            shift
            ;;
        --version)
            ver="${2-}"
            shift
            ;;
        -?*) echo "Unknown option: $1" ;;
        *) break ;;
    esac
    shift
done
if [[ -z "$ver" ]]; then
    echo "Missing required parameter for package version: --version"
    exit 1
fi
if [[ -z "${pro_file}" ]]; then
    echo "Missing required parameter for project file: -p | --project"
    exit 1
fi
if [[ -z "$execs" ]]; then
    echo "Missing required parameter for executables: -e | --executables"
    exit 1
fi
if [[ -z ${njobs} || ${njobs} -gt ${MAXNJOBS} ]]; then
    njobs=${MAXNJOBS}
fi
if [[ -z "${dist_dir}" ]]; then
    dist_dir="dist"
fi
if [[ -z "${app_name}" ]]; then
    app_name="qt-app"
fi

echo "NJobs: $njobs"
echo "Version: $ver"
echo "Project: $pro_file"
echo "Executables: $execs"
echo "Dist dir: $dist_dir"
echo "App Name: $app_name"

# main executable
exec0=$(echo ${execs} | cut -d' ' -f1)

# building
cd /appbuilder
qmake CONFIG+=release CONFIG+=optimize_full ${pro_file}
make -j${njobs}

# bundling
[[ ! -e ${dist_dir} ]] && mkdir -p ${dist_dir}
cp -r ${execs} ${dist_dir}
cd ${dist_dir}
for app in ${execs}
do
    linuxdeployqt ${app} -qmake=qmake ${QT_DEPLOYER_OPTS}
    # find . -iname '*.so' -exec strip --strip-unneeded {} \;
    strip --strip-unneeded ${app}
done

cat << EOF > run_app.sh
#!/bin/sh
cwdir=\`dirname \$0\`
\${cwdir}/${exec0}
EOF
chmod +x run_app.sh

cd ..
tar cjf /appbuilder/${app_name}_${ver}.orig.tar.bz2 ${dist_dir}

# makeself
makeself ${MAKESELF_OPTS} ${dist_dir} /appbuilder/${app_name}_${ver}.run \
    "${app_name} with Qt Framework" ./run_app.sh