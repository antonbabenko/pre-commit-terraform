# hadolint ignore=DL3006
FROM pre-commit

# hadolint ignore=DL3008
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        datamash \
        time && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

WORKDIR /pct
ENTRYPOINT [ "/pct/tests/hooks_performance_test.sh" ]
