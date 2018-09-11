FROM mbentley/awscli:latest
MAINTAINER Matt Bentley <mbentley@mbentley.net>

RUN apk --no-cache add jq
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
