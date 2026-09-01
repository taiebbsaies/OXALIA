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

ENV SONAR_SCANNER_VERSION=6.2.1.4610
RUN curl -sSLo /tmp/sonar-scanner.zip \
        "https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-${SONAR_SCANNER_VERSION}-linux-x64.zip" \
    && unzip -q /tmp/sonar-scanner.zip -d /opt \
    && mv "/opt/sonar-scanner-${SONAR_SCANNER_VERSION}-linux-x64" /opt/sonar-scanner \
    && rm /tmp/sonar-scanner.zip \
    && ln -sf /opt/sonar-scanner/bin/sonar-scanner /usr/local/bin/sonar-scanner \
    && chmod 755 /opt/sonar-scanner/bin/sonar-scanner

USER jenkins
ENV PATH="/opt/sonar-scanner/bin:${FLUTTER_HOME}/bin:${PATH}"
RUN git config --global --add safe.directory "${FLUTTER_HOME}" \
    && flutter config --no-analytics \
    && flutter precache --no-web --no-linux --no-windows --no-macos --no-fuchsia \
    && flutter doctor
