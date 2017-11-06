#!/bin/sh
set -uex

# MIRROR='https://mirrors.kernel.org/archlinux'
MIRROR='https://mirror.f4st.host/archlinux'
ISO_VER='2017.11.01'
NAME="vpalazzo/archlinux"

ENTRYPOINT='#!/bin/sh
cd
export USER="$(id -un)"
. /etc/profile
exec "$@"
'

DOCKERFILE='
FROM scratch

ADD root.x86_64 /

RUN \
    set -x &&\
    ln -nfs /usr/share/zoneinfo/Europe/Rome /etc/localtime &&\
    echo "en_US.UTF-8 UTF-8" >/etc/locale.gen &&\
    echo "LANG=en_US.UTF-8" >/etc/locale.conf &&\
    rm /etc/ssl/certs/ca-certificates.crt &&\
    pacman-key --init &&\
    pacman-key --populate archlinux &&\
    echo "Server = http://mirror.f4st.host/archlinux/\$repo/os/\$arch" \
         >/etc/pacman.d/mirrorlist &&\
    pacman --noconfirm -Sy sed gzip &&\
    pacman --noconfirm -Su ca-certificates-utils &&\
    sed -i~ '"'"'/^#\[multilib\]$/{s/^#//;n;s/^#//}'"'"' /etc/pacman.conf &&\
    pacman --noconfirm -Sy

RUN \
    echo '"'$(echo "$ENTRYPOINT" | base64 --wrap=0)'"' |\
        base64 -d >/entrypoint.sh &&\
    chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]

CMD [ "/usr/bin/bash", "-l" ]
'

DOCKERFILE_BUILDER='
FROM alpine:3.6

RUN apk --update add curl

RUN \
    mkdir /root/src/ &&\
    curl -L '"'${MIRROR}/iso/${ISO_VER}/`
           `archlinux-bootstrap-${ISO_VER}-x86_64.tar.gz'"' \
        | tar xzC /root/src/

RUN \
    echo '"'$(echo "$DOCKERFILE" | base64 --wrap=0)'"' |\
        base64 -d >/root/src/Dockerfile
'

echo "$DOCKERFILE_BUILDER" \
    | docker build --force-rm --pull --tag "$NAME"-builder:"$ISO_VER" -

docker run --rm "$NAME"-builder:"$ISO_VER" tar cC /root/src . \
    | docker build --force-rm --tag "$NAME":"$ISO_VER" -

exec docker run -ti --rm "$NAME":"$ISO_VER" "$@"
