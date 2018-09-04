# Build Archlinux packages with drone
#
#     docker build --rm=true -t asavartzeth/arch-travis .

FROM archimg/base-devel:latest
MAINTAINER Patrik Nilsson <asavartzeth@gmail.com>

# Setup build user/group
ENV UGID='2000' UGNAME='travis'
RUN \
    groupadd --gid "$UGID" "$UGNAME" && \
    useradd --create-home --uid "$UGID" --gid "$UGID" --shell /usr/bin/false "${UGNAME}"

# copy sudoers file
COPY contrib/etc/sudoers.d/$UGNAME /etc/sudoers.d/$UGNAME

RUN \
    # Update
    pacman -Syu \
        git \
        --noconfirm && \
    # Clean .pacnew files
    find / -name "*.pacnew" -exec rename .pacnew '' '{}' \;

RUN \
    chmod 'u=r,g=r,o=' /etc/sudoers.d/$UGNAME

USER $UGNAME

ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/usr/bin/core_perl

# Add arch-travis script
COPY init.sh /usr/bin/arch-travis

ENTRYPOINT ["/usr/bin/arch-travis"]
