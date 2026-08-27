# Disposable test environment for scrcpy-autostart Ubuntu verification.
# Built and run by test/test-in-docker.sh — see that script for usage.

FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

# Tooling needed to lint and drive the install/uninstall scripts.
RUN apt-get update && apt-get install -y --no-install-recommends \
        bash \
        sudo \
        shellcheck \
        curl \
        unzip \
        procps

# Non-root user with passwordless sudo, mirroring a real Ubuntu desktop user
RUN useradd -m -s /bin/bash tester \
    && echo "tester ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/tester \
    && chmod 0440 /etc/sudoers.d/tester

USER tester
WORKDIR /workspace
