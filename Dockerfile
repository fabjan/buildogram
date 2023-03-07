ARG ELIXIR_VERSION=1.14.2
ARG ERLANG_VERSION=25.1.2

FROM elixir:${ELIXIR_VERSION}-alpine AS builder

# Setup gleam
ENV GLEAM_VERSION=0.27.0
RUN wget https://github.com/gleam-lang/gleam/releases/download/v${GLEAM_VERSION}/gleam-v${GLEAM_VERSION}-x86_64-unknown-linux-musl.tar.gz
RUN tar -xzf gleam-v${GLEAM_VERSION}-x86_64-unknown-linux-musl.tar.gz
RUN mv gleam /usr/local/bin/gleam

# Prepare the dependencies
COPY gleam.toml /build/
COPY manifest.toml /build/
WORKDIR /build
# TODO: is it possible to build the dependencies only, not just download them?
RUN gleam deps download

# Add project code
COPY src /build/src

# Compile the project
RUN gleam export erlang-shipment

# Copy to clean runtime image
FROM erlang:${ERLANG_VERSION}-alpine AS runtime
COPY --from=builder /build/build/erlang-shipment /app

# Run the server
EXPOSE 3000
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
