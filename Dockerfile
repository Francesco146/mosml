# Build stage - compile Moscow ML from source
FROM --platform=linux/amd64 ubuntu:22.04 AS builder

ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    binutils \
    build-essential \
    ca-certificates \
    libgmp-dev \
    perl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy source code
COPY . /mosml-src

# Build Moscow ML
WORKDIR /mosml-src/src
RUN make clean && \
    make world && \
    make DESTDIR=/mosml-install PREFIX=/usr/local install

# Runtime stage - minimal image with only runtime dependencies
FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    libc6 \
    libgmp10 \
    rlwrap && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Copy installed Moscow ML from builder
COPY --from=builder /mosml-install/usr/local /usr/local

# Create workspace directory
WORKDIR /workspace

# Add labels
LABEL org.opencontainers.image.title="Moscow ML"
LABEL org.opencontainers.image.description="Moscow ML is a light-weight implementation of Standard ML (SML), a strict functional language widely used in teaching and research."
LABEL org.opencontainers.image.source="https://github.com/Francesco146/mosml"

# Default command is interactive REPL
ENTRYPOINT ["mosml"]
