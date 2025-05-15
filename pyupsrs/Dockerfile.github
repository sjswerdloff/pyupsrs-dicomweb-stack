FROM python:3.11-slim

# Install git and pipx
RUN apt-get update && \
    apt-get install -y --no-install-recommends git pipx && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r appuser && useradd -r -g appuser -m appuser

# Switch to non-root user
USER appuser
WORKDIR /home/appuser

# Ensure pipx is in PATH
ENV PATH="/home/appuser/.local/bin:${PATH}"
ENV PIPX_HOME="/home/appuser/.local/pipx"
ENV PIPX_BIN_DIR="/home/appuser/.local/bin"

# Install pyupsrs from GitHub using pipx
# Replace with the actual GitHub repository URL
ARG GITHUB_REPO="https://github.com/sjswerdloff/py-ups-rs.git"
ARG GITHUB_BRANCH="main"
RUN pipx install git+${GITHUB_REPO}@${GITHUB_BRANCH}

# Set environment variable for better logging
ENV PYTHONUNBUFFERED=1

# Expose the port
EXPOSE 8000

# Run the application
CMD ["pyupsrs", "--host", "0.0.0.0", "--port", "8000"]
