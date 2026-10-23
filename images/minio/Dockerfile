ARG VERSION=RELEASE.2025-10-15T17-29-55Z
FROM alpine:3.21
ARG VERSION
ARG TARGETARCH
RUN apk add --no-cache ca-certificates curl \
  && case "${TARGETARCH}" in \
       amd64) MINIO_ARCH=amd64 ;; \
       arm64) MINIO_ARCH=arm64 ;; \
       *) echo "unsupported TARGETARCH=${TARGETARCH}" >&2; exit 1 ;; \
     esac \
  && curl -fsSL \
       "https://github.com/minio/minio/releases/download/${VERSION}/minio.linux-${MINIO_ARCH}.${VERSION}" \
       -o /usr/local/bin/minio \
  && chmod +x /usr/local/bin/minio \
  && apk del curl \
  && adduser -D -u 1000 minio-user
USER 1000
ENTRYPOINT ["/usr/local/bin/minio"]
