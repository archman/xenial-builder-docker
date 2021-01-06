#!/bin/bash

QT_DEPLOYER_PATH=/tmp/squashfs-root/AppRun
QT_DEPLOYER_OPTS="-bundle-non-qt-libs -no-translations"
MAKESELF_PATH=makeself
MAKESELF_OPTS="--notemp --nox11"
QMAKE=/usr/lib/qt-new/bin/qmake
MAXNJOBS=$(cat /proc/cpuinfo | grep processor | wc -l)

njobs=''
ver=''
while :; do
    case "${1-}" in
        -j | --jobs)
            njobs="${2-}"
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
    echo "Missing required parameter: --version"
    exit 1
fi
if [[ -z ${njobs} || ${njobs} -gt ${MAXNJOBS} ]]; then
    njobs=${MAXNJOBS}
fi

cd /appbuilder
[[ ! -e LISEcute.pro ]] && bash -i

# building
${QMAKE} CONFIG+=release CONFIG+=optimize_full LISEcute.pro
make -j${njobs}

# bundling

mkdir lise-app
cp -r LISE++ _install lise-app
cd lise-app
rm $(find _install -iname '*.dll' -o -iname '*.exe' | xargs)
find _install -empty -type d -delete

${QT_DEPLOYER_PATH} LISE++ -qmake=${QMAKE} ${QT_DEPLOYER_OPTS}
# find . -iname '*.so' -exec strip --strip-unneeded {} \;
strip --strip-unneeded LISE++

cat << EOF > run_lise.sh
#!/bin/sh
cwdir=\`dirname \$0\`
\${cwdir}/LISE++ \${cwdir}/_install
EOF
chmod +x run_lise.sh

cp _install/lisepp.ini _install/lisepp_original.ini
sed -e '/^size/s/size=.*/size=11/;/^sound/s/sound=.*/sound=0/;/^3d/s/3d.*/3d-animation=0/;/^table/s/table=.*/table=-1/;s/^M$//' _install/lisepp_original.ini  > _install/lisepp.ini
dos2unix _install/lisepp.ini

cd ..
tar cjf /appbuilder/lise-app_${ver}.orig.tar.bz2 lise-app

# makeself
${MAKESELF_PATH} ${MAKESELF_OPTS} lise-app /appbuilder/lise_${ver}.run \
    "LISE++ with Qt Framework" ./run_lise.sh
