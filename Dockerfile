FROM debian:13.3-slim

RUN set -euxo pipefail && \
  DEBIAN_FRONTEND=noninteractive && \
  # Add APT repositories
  apt-get update && apt-get install --yes --no-install-recommends ca-certificates curl gnupg lsb-release && \
  # Setup zfs package
  # https://openzfs.github.io/openzfs-docs/Getting%20Started/Debian/index.html
  . /etc/os-release && \
  ARCH="$(dpkg --print-architecture)" && \
  echo "deb http://deb.debian.org/$ID stable contrib" > /etc/apt/sources.list.d/stable-contrib.list && \
  # Add Backports
  echo "deb http://deb.debian.org/debian $VERSION_CODENAME-backports main contrib non-free-firmware" >> /etc/apt/sources.list.d/backports.list && \
  echo "deb-src http://deb.debian.org/debian $VERSION_CODENAME-backports main contrib non-free-firmware" >> /etc/apt/sources.list.d/backports.list && \
  # Pin ZFS Backports
  echo "Package: src:zfs-linux" >> /etc/apt/preferences.d/90_zfs && \
  echo "Pin: release n=$VERSION_CODENAME-backports" >> /etc/apt/preferences.d/90_zfs && \
  echo "Pin-Priority: 990" >> /etc/apt/preferences.d/90_zfs && \
  apt-get update && \
  # Install user-land ZFS utils dependency
  apt-get install --yes --no-install-recommends zfsutils-linux && \
  # copy zrepl binary to the image
  cp ./bin/zrepl /usr/bin/zrepl && \
  # zrepl expects /var/run/zrepl
  mkdir -p /var/run/zrepl && chmod 0700 /var/run/zrepl && \
  # Reduce final Docker image size: Clear the APT cache
  apt-get clean && rm -rf /var/lib/apt/lists/* && \
  # check versions
  zrepl version --show client && \
  zfs --version 2>/dev/null || true &&\
  # verify zfs is installed
  zfs --help && \
  zpool --help

CMD ["daemon"]
ENTRYPOINT ["/usr/bin/zrepl", "--config", "/etc/zrepl/zrepl.yml"]

WORKDIR /etc/zrepl
