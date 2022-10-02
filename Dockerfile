FROM ghcr.io/jtrim777-dev/bazelbase:latest

RUN /usr/bin/installgcc

COPY action.sh /usr/bin/execute_gh

ENTRYPOINT ["/usr/bin/execute_gh"]
