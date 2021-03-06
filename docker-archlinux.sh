#!/bin/sh
set -ue

# MIRROR='https://mirrors.kernel.org/archlinux'
MIRROR='https://mirror.f4st.host/archlinux'
ISO_VER='2018.05.01'
NAME="vpalazzo/archlinux"

ENTRYPOINT='#!/bin/sh
cd
export USER="$(id -un)"
. /etc/profile
exec "$@"
'

DOCKERFILE='
FROM alpine:3.7 as builder

RUN apk --no-cache add curl

RUN \
  cd &&\
  curl -L '"'${MIRROR}/iso/${ISO_VER}/`
          `archlinux-bootstrap-${ISO_VER}-x86_64.tar.gz'"' \
  | tar xz

FROM scratch

COPY --from=builder /root/root.x86_64/ /

RUN \
    set -x -- &&\
    ln -nfs /usr/share/zoneinfo/Europe/Rome /etc/localtime &&\
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen &&\
    echo "LANG=en_US.UTF-8" >/etc/locale.conf &&\
    pacman-key --init &&\
    pacman-key --populate archlinux &&\
    echo "Server = '"${MIRROR}"'/\$repo/os/\$arch" \
         >/etc/pacman.d/mirrorlist &&\
    pacman --noconfirm -Sy

RUN \
    echo '"'$(echo "$ENTRYPOINT" | base64 --wrap=0)'"' |\
        base64 -d >/entrypoint.sh &&\
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "/usr/bin/bash", "-l" ]
'

echo "$DOCKERFILE" \
    | docker build --force-rm --tag "$NAME":"$ISO_VER" - \
             > /tmp/"$(basename "$0")".log

exec docker run -ti --rm "$NAME":"$ISO_VER" "$@"
