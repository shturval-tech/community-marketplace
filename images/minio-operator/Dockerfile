# Rebuild operator with current Go toolchain (quay.io tag ships older stdlib/x/crypto).
ARG VERSION=v7.1.1
FROM golang:1.25-alpine AS build
ARG VERSION
ARG TARGETARCH
RUN apk add --no-cache git ca-certificates \
  && git clone --depth 1 --branch "${VERSION}" https://github.com/minio/operator.git /src \
  && cd /src \
  && CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" \
     go build -trimpath -ldflags "-s -w" -o /minio-operator ./cmd/operator

FROM alpine:3.21
RUN apk add --no-cache ca-certificates \
  && adduser -D -u 1000 -H operator
COPY --from=build /minio-operator /minio-operator
USER 1000
ENTRYPOINT ["/minio-operator"]
