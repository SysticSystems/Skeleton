FROM ghcr.io/systicsystems/synapse:latest

# Accept host user identifiers (passed dynamically from synapse.sh)
ARG USER_UID=1000
ARG USER_GID=1000

# Create a non-root developer user matching the host UID/GID
RUN groupadd --gid ${USER_GID} developer && \
    useradd --uid ${USER_UID} --gid ${USER_GID} --create-home --shell /bin/bash developer && \
    chown -R ${USER_UID}:${USER_GID} /home/developer

# Switch to the non-root developer user
USER developer

# Target mount point for project codebase
WORKDIR /project