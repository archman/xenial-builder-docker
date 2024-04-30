# Ubuntu-builder-docker

Package building environment for Qt projects, based on Ubuntu LTS releases.

As of Qt 6.5.2 introduced, Ubuntu 20.04 Focal Fossa is being used, not based on Xenial (16.04) anymore.

# Images

* **tonyzhang/xenial-builder:1.0**
  * `linuxdeployqt-7`, `Qt 5.15.2` (+Qt Charts)

* **tonyzhang/xenial-builder:2.0**
  * +gsl
  
* **tonyzhang/focal-builder:4.0**
  * `Qt 6.5.2` (+Qt Data Visualization, +Qt5Compatlibs)

* **tonyzhang/focal-builder:5.4**, `Qt 6.7.0`
  - with `linuxdeployqt@2b38449`, released 2023/12/27
  - Qt Charts
  - Qt Data Visualization
  - Qt Multimedia
  - Qt5 Compatibility Module
  - Installed dependencies and fixed libqsqlmimer.so issue.

## glibc compatibility

* xenial-builder: >= 2.23
* focal-builder: >= 2.31


# Examples

```bash
docker run -v <source-dir>:/appbuilder -it --rm \
    -u "$(id -u):$(id -g)" \
    tonyzhang/focal-builder:5.4.1 \
    --version "<package-version>" \
    --executables "<executables>" \
    --project "<project file>" \
    --app "<app name>"
```