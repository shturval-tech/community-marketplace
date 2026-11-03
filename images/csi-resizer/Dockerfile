# Rebuild v1.14.0 with patched Go stdlib and google.golang.org/grpc (upstream tag unchanged).
ARG VERSION=v1.14.0
FROM golang:1.25.7-alpine AS build
ARG VERSION
ARG TARGETARCH
RUN apk add --no-cache git ca-certificates \
  && git clone --depth 1 --branch "${VERSION}" https://github.com/kubernetes-csi/external-resizer.git /src \
  && cd /src \
  && go get google.golang.org/grpc@v1.79.3 \
  && go mod tidy \
  && rm -rf vendor \
  && CGO_ENABLED=0 GOOS=linux GOARCH="${TARGETARCH}" \
     go build -mod=mod -trimpath -ldflags "-s -w" -o /csi-resizer ./cmd/csi-resizer

FROM gcr.io/distroless/static:latest
COPY --from=build /csi-resizer /csi-resizer
ENTRYPOINT ["/csi-resizer"]
