FROM ghcr.io/gleam-lang/gleam:v0.25.0-erlang-alpine AS builder

# Prepare the dependencies
# TODO: is it possible to use elixir from an image instead of installing it?
RUN apk add --no-cache elixir
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
