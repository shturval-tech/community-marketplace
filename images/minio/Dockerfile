# MinIO CE: upstream releases after 2025-10 ship source-only (no GitHub/dl.min.io binaries).
ARG VERSION=RELEASE.2025-10-15T17-29-55Z
FROM golang:1.25-alpine AS build
ARG VERSION
ARG TARGETARCH
RUN apk add --no-cache git ca-certificates \
  && CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" \
     go install -ldflags="-s -w" "github.com/minio/minio@${VERSION}"

FROM alpine:3.21
RUN apk add --no-cache ca-certificates \
  && adduser -D -u 1000 minio-user
COPY --from=build /go/bin/minio /usr/local/bin/minio
USER 1000
ENTRYPOINT ["/usr/local/bin/minio"]
