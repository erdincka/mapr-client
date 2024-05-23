FROM --platform=linux/amd64 ubuntu:20.04

LABEL org.opencontainers.image.authors="erdincka@msn.com"

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y
RUN apt install -y ca-certificates locales syslinux syslinux-utils
ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
RUN locale-gen $LC_ALL
RUN apt install -y --no-install-recommends gnupg2 python3 python3-pip python3-dev \
    libgcc1 openjdk-11-jdk openssh-client nfs-common build-essential \
    lsb-core libcurl3-gnutls putty sudo git wget curl

# Workaround for MFS-18734
# RUN wget http://archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.0g-2ubuntu4_amd64.deb
# RUN dpkg -i libssl1.1_1.1.0g-2ubuntu4_amd64.deb

# ## Enable mapr repository
COPY ./mapr.list /etc/apt/sources.list.d/mapr.list
COPY ./maprgpg.key /tmp/maprgpg.key
RUN cat /tmp/maprgpg.key | apt-key add -
RUN apt clean
RUN apt update

## Ensure user
ENV MAPR_USER=mapr
ENV MAPR_PASS=mapr
RUN useradd -u 5000 -U -m -d /home/${MAPR_USER} -s /bin/bash -G sudo ${MAPR_USER}
RUN echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd
RUN echo "root:${MAPR_PASS}" | chpasswd
RUN echo "mapr ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/mapr

# Install the mapr packages
RUN apt install -y mapr-edf-clients

# Enable streams and db clients
RUN pip3 install --global-option=build_ext --global-option="--library-dirs=/opt/mapr/lib" --global-option="--include-dirs=/opt/mapr/include/" mapr-streams-python
RUN pip3 install maprdb-python-client
ENV LD_LIBRARY_PATH=/opt/mapr/lib
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

ADD ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Environment for JWT auth mechanism
ENV MAPR_JWT_TOKEN_LOCATION="/root/jwt_access"
ENV MAPR_JWT_REFRESH_TOKEN_LOCATION="/root/jwt_refresh"

ENTRYPOINT [ "/entrypoint.sh" ]
