FROM golang AS builder
ARG RCLONE_REPO=https://github.com/rclone/rclone
ARG RCLONE_BRANCH=master
RUN git clone ${RCLONE_REPO} /go/src/github.com/rclone/rclone/
WORKDIR /go/src/github.com/rclone/rclone/
RUN git checkout ${RCLONE_BRANCH}

RUN \
  CGO_ENABLED=0 \
  make
RUN ./rclone version

# Begin final image
FROM alpine:latest

RUN apk --no-cache add ca-certificates fuse3 tzdata && \
  echo "user_allow_other" >> /etc/fuse.conf

COPY --from=builder /go/src/github.com/rclone/rclone/rclone /usr/local/bin/

RUN addgroup -g 1009 rclone && adduser -u 1009 -Ds /bin/sh -G rclone rclone

#ENTRYPOINT [ "rclone" ]

WORKDIR /data
ENV XDG_CONFIG_HOME=/config

WORKDIR /

COPY ./sync.sh /etc/sync.sh

RUN chmod 755 /etc/sync.sh

RUN apk add inotify-tools

ENTRYPOINT ["sh", "/etc/sync.sh"]
