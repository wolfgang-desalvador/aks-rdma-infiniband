ARG UBUNTU_VERSION
FROM ubuntu:$UBUNTU_VERSION as debs
ARG UBUNTU_VERSION
ARG MELLANOX_VERSION

# Install ISO from nvidia

WORKDIR /opt/debs
COPY download.sh download.sh 
RUN echo $UBUNTU_VERSION
USER root
RUN sed -i "s/<ubuntu_version>/$UBUNTU_VERSION/g" download.sh
RUN sed -i "s/<mellanox_version>/$MELLANOX_VERSION/g" download.sh
RUN bash download.sh

FROM ubuntu:$UBUNTU_VERSION

COPY --from=debs /opt/debs /opt/debs
COPY entrypoint.sh /entrypoint.sh 
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]