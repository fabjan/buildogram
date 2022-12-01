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
import gleam/string
import gleam/result
import gleam/erlang/process
import gleam/erlang/os
import gleam/http/elli
import buildogram/http_server
import buildogram/http_client
import buildogram/util

pub fn main() {
  let port =
    os.get_env("PORT")
    |> result.then(int.parse)
    |> result.unwrap(3000)

  // TODO: use supervisor
  // Start our dependencies
  try client =
    http_client.start()
    |> util.snag_context("starting HTTP client")

  // Start the web server process
  try server = http_server.stack(client)
  assert Ok(_) = elli.start(server, on_port: port)

  ["Listening on localhost:", int.to_string(port), " ✨"]
  |> string.concat
  |> io.println

  // TODO: signal handling
  Ok(process.sleep_forever())
}
