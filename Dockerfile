FROM elixir:1.14.2-alpine AS builder

# Setup gleam
RUN wget https://github.com/gleam-lang/gleam/releases/download/v0.25.0/gleam-v0.25.0-x86_64-unknown-linux-musl.tar.gz
RUN tar -xzf gleam-v0.25.0-x86_64-unknown-linux-musl.tar.gz
RUN mv gleam /usr/local/bin/gleam

# Prepare the dependencies
# TODO: is it possible to use elixir from an image instead of installing it?
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
FROM erlang:25.1.2.0-alpine AS runtime
COPY --from=builder /build/build/erlang-shipment /app

# Run the server
WORKDIR /app
ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["run"]
