ARG ubuntu_version
FROM ubuntu:$ubuntu_version as debs

# Install ISO from nvidia

WORKDIR /opt/debs
COPY download.sh download.sh 
USER root
RUN bash download.sh $ubuntu_version

FROM ubuntu:$ubuntu_version

COPY --from=debs /opt/debs /opt/debs
COPY entrypoint.sh /entrypoint.sh 
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]


