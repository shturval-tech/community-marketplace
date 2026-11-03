ARG VERSION=1.3.0
FROM quay.io/strimzi/operator:${VERSION}
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
