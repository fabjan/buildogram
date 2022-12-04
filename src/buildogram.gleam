////   Copyright 2022 Fabian Bergström
////
////   Licensed under the Apache License, Version 2.0 (the "License");
////   you may not use this file except in compliance with the License.
////   You may obtain a copy of the License at
////
////       http://www.apache.org/licenses/LICENSE-2.0
////
////   Unless required by applicable law or agreed to in writing, software
////   distributed under the License is distributed on an "AS IS" BASIS,
////   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
////   See the License for the specific language governing permissions and
////   limitations under the License.

import gleam/io
import gleam/int
import gleam/result
import gleam/erlang/process
import gleam/erlang/os
import gleam/http/elli
import buildogram/http_server
import buildogram/http_client
import buildogram/util

const default_port = 3000

const default_cache_size = 100

fn log(s) {
  io.println("[main] " <> s)
}

pub fn main() {
  let port =
    os.get_env("PORT")
    |> result.then(int.parse)
    |> result.lazy_unwrap(fn() {
      log("🛠  Default port: " <> int.to_string(default_port))
      default_port
    })

  let cache_size =
    os.get_env("BUILDOGRAM_CACHE_SIZE")
    |> result.then(int.parse)
    |> result.lazy_unwrap(fn() {
      log("🛠  Default cache size: " <> int.to_string(default_cache_size))
      default_cache_size
    })

  // TODO: use supervisor
  // Start our dependencies
  try client =
    http_client.start(cache_size)
    |> util.snag_context("starting HTTP client")

  // Start the web server process
  try server = http_server.stack(client)
  assert Ok(_) = elli.start(server, on_port: port)

  log("✨ Buildogram is now listening on :" <> int.to_string(port))
  log("Use Ctrl+C to break")

  // TODO: signal handling
  Ok(process.sleep_forever())
}
