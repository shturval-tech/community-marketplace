ARG VERSION=4.4.0-management
FROM docker.io/library/rabbitmq:${VERSION}
USER root
RUN apt-get update \
  && apt-get install -y --only-upgrade gpgv \
  && rm -rf /var/lib/apt/lists/*
USER rabbitmq
