IMAGE := tonyzhang/focal-builder:5.4
VER := 15.1.8

download:
	wget https://gitlab.msu.edu/zhangto71/packages/-/raw/xenial/xenial/qt_5.15.2.1-1_all.deb
	wget https://github.com/probonopd/linuxdeployqt/releases/download/7/linuxdeployqt-7-x86_64.AppImage

clean:
	/bin/rm qt_5.15.2.1-1_all.deb linuxdeployqt-7-x86_64.AppImage

build:
	docker build -t $(IMAGE) .

run:
	docker run -it --rm $(IMAGE) --version 0.1

push:
	# docker build --no-cache -t $(IMAGE) .
	docker push $(IMAGE)

build-lise:
	./build_lise.sh --input lise_$(VER).tar.gz --src-version $(VER) --output pkg

