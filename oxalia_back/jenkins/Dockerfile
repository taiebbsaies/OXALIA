FROM jenkins/jenkins:lts-jdk21

USER root
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv \
        python3-pip \
        python3-dev \
        git \
        curl \
        unzip \
        xz-utils \
        zip \
        libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

ENV FLUTTER_HOME=/opt/flutter
RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git "${FLUTTER_HOME}" \
    && chown -R jenkins:jenkins "${FLUTTER_HOME}" \
    && git config --global --add safe.directory "${FLUTTER_HOME}"

USER jenkins
ENV PATH="${FLUTTER_HOME}/bin:${PATH}"
RUN git config --global --add safe.directory "${FLUTTER_HOME}" \
    && flutter config --no-analytics \
    && flutter precache --no-web --no-linux --no-windows --no-macos --no-fuchsia \
    && flutter doctor
