FROM ubuntu:16.04
LABEL maintainer="Tong Zhang <zhangt@frib.msu.edu>"

WORKDIR /appbuilder

RUN apt-get update && \
    apt-get install --no-install-recommends -y \
        make g++ libglib2.0-0 libgl1-mesa-dev libgssapi-krb5-2 \
        dos2unix bzip2 \
        libfontconfig1 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 \
        libxcb-render-util0 libxcb-xinerama0 libxcb-xkb1 \
        libxkbcommon-x11-0 libdbus-1-3 libegl1-mesa libcups2 \
        makeself && \
    rm -rf /var/lib/apt/lists/*

COPY qt_5.15.2-*_all.deb linuxdeployqt-7-x86_64.AppImage /tmp/
RUN cd /tmp && dpkg -i /tmp/qt*.deb && \
    chmod +x linuxdeployqt-7-x86_64.AppImage && \
    ./linuxdeployqt-7-x86_64.AppImage --appimage-extract && \
    rm linuxdeployqt-7-x86_64.AppImage qt*.deb

ADD https://ftp.wayne.edu/gnu/gsl/gsl-2.6.tar.gz /tmp/
RUN tar xf /tmp/gsl-2.6.tar.gz -C /tmp && cd /tmp/gsl-2.6 && ./configure && make && make install && cd /tmp && rm -rf gsl-2.6*

ADD entrypoint.sh /usr/bin/
ENTRYPOINT ["entrypoint.sh"]
