# Rick Agent — Startup Factory OS
# Reuses the openclaw-deploy base
FROM ghcr.io/yevgeniusr/openclaw-deploy:main

USER root

# Install Python + psycopg2 for bot coordination / DB access
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 python3-pip python3-venv \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install psycopg2-binary python-dotenv requests

USER node

# Copy Rick-specific files
COPY --chown=node:node rick-agent/ /home/node/rick-agent/
RUN chmod +x /home/node/rick-agent/entrypoint.sh

WORKDIR /data/workspace/startup-factory

ENTRYPOINT ["/home/node/rick-agent/entrypoint.sh"]
