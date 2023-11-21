ARG GLEAM_VERSION=0.32.4
ARG ERLANG_VERSION=26.0.2

FROM ghcr.io/gleam-lang/gleam:v${GLEAM_VERSION}-elixir AS builder

# Prepare the dependencies
COPY gleam.toml /build/
COPY manifest.toml /build/
WORKDIR /build
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
