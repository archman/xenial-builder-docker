FROM ubuntu:20.04
LABEL maintainer="Tong Zhang <zhangt@frib.msu.edu>"

WORKDIR /appbuilder

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        make g++ libglib2.0-0 libgl1-mesa-dev libgssapi-krb5-2 \
        dos2unix bzip2 \
        libfontconfig1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
        libxcb-render-util0 libxcb-randr0 libmysqlclient21 \
        libxcb-xinerama0 libxcb-xkb1 libxcb-shape0 \
        libxkbcommon-x11-0 libdbus-1-3 libegl1-mesa libcups2 \
        libxcb-cursor-dev libodbc1 libpq-dev \
        xz-utils makeself && \
    rm -rf /var/lib/apt/lists/*

COPY qt_6.5.2-1_all.deb linuxdeployqt-continuous-x86_64.AppImage /tmp/
RUN cd /tmp && dpkg -i /tmp/qt*.deb && \
    chmod +x linuxdeployqt-continuous-x86_64.AppImage && \
    ./linuxdeployqt-continuous-x86_64.AppImage --appimage-extract && \
    rm linuxdeployqt-continuous-x86_64.AppImage qt*.deb

ADD https://ftp.wayne.edu/gnu/gsl/gsl-2.7.tar.gz /tmp/
RUN tar xf /tmp/gsl-2.7.tar.gz -C /tmp && \
    cd /tmp/gsl-2.7 && ./configure && make -j4 && make install && \
    cd /tmp && rm -rf gsl-2.7* && \
    echo "/usr/local/lib" > /etc/ld.so.conf.d/local.conf && ldconfig

ADD entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]
