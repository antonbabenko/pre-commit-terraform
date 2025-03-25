# We use `latest` tag for tests proposes
# hadolint ignore=DL3007
FROM pre-commit-terraform:latest

RUN apk add --no-cache \
    datamash=~1.8

WORKDIR /pct
ENTRYPOINT [ "/pct/tests/hooks_performance_test.sh" ]
