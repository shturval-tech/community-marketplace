ARG VERSION=1.3.0-kafka-4.2.2
FROM quay.io/strimzi/kafka:${VERSION}
USER 0
RUN microdnf upgrade -y \
    ca-certificates \
    curl-minimal \
    expat \
    libcurl-minimal \
    pcre2 \
    pcre2-syntax \
    python3 \
    python3-libs \
  && microdnf clean all
USER 1001
