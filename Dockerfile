FROM --platform=linux/amd64 ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update
RUN apt upgrade -y
RUN apt install -y ca-certificates locales syslinux syslinux-utils
ENV SHELL=/bin/bash \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
RUN locale-gen $LC_ALL
RUN apt install -y --no-install-recommends gnupg2 python3-pip python3-dev wget curl \
    libgcc1 openjdk-11-jdk openssh-client openssh-server nfs-common build-essential lsb-core libcurl3-gnutls putty sudo

## Ensure user
ENV MAPR_USER=mapr
ENV MAPR_PASS=mapr
RUN useradd -u 5000 -U -m -d /home/${MAPR_USER} -s /bin/bash -G sudo ${MAPR_USER}
RUN echo "${MAPR_USER}:${MAPR_PASS}" | chpasswd
RUN echo "root:${MAPR_PASS}" | chpasswd
RUN echo "mapr ALL=(ALL) NOPASSWD: ALL" | tee /etc/sudoers.d/mapr

## Enable mapr repository
COPY ./mapr.list /etc/apt/sources.list.d/mapr.list
# COPY ./auth.conf /etc/apt/auth.conf.d/mapr.conf
COPY ./maprgpg.key /tmp/maprgpg.key
RUN cat /tmp/maprgpg.key | apt-key add -
# RUN echo /tmp/maprgpg.key | gpg --dearmor -o /usr/share/keyrings/mapr-archive.gpg
RUN apt clean
RUN apt update
# Install the mapr packages
RUN apt install -y mapr-core mapr-client mapr-posix-client-basic

# Enable streams and db clients
RUN pip3 install --global-option=build_ext --global-option="--library-dirs=/opt/mapr/lib" --global-option="--include-dirs=/opt/mapr/include/" mapr-streams-python
RUN pip3 install maprdb-python-client
ENV LD_LIBRARY_PATH=/opt/mapr/lib
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64

# ## Enable spark and delta lake
RUN pip3 install pandas numpy wheel faker pyspark tqdm boto3
RUN apt install -y mapr-spark
RUN pip3 install requests delta-spark==2.3.0 avro-python3==1.10.2
# RUN pip3 install jupyterlab

ADD ./start.sh /start.sh
RUN chmod +x /start.sh

ADD ./app /workspace
# Finalize client configuration
WORKDIR /workspace
EXPOSE 8080
EXPOSE 8090
EXPOSE 22
ENTRYPOINT [ "/start.sh" ]
