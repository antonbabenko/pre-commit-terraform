FROM pre-commit-terraform:latest

RUN apt update && \
    apt install -y \
        datamash \
        time && \
    # Cleanup
    rm -rf /var/lib/apt/lists/*

WORKDIR /pct
ENTRYPOINT [ "/pct/tests/hooks_performance_test.sh" ]
