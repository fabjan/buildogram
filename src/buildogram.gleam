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
import gleam/option.{Some}
import gleam/result
import gleam/erlang
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/elli
import buildogram/http_server
import buildogram/http_client
import outil.{CommandError, CommandResult, print_usage_and_exit}
import outil/opt
import snag.{Snag}

fn log(s) {
  io.println_error("[main] " <> s)
}

pub fn get_env(
  name: String,
  parse: fn(String) -> Result(a, Nil),
  default: a,
) -> a {
  os.get_env(name)
  |> result.then(parse)
  |> result.unwrap(default)
}

pub fn main_cmd(args: List(String)) -> CommandResult(Nil, Snag) {
  use cmd <- outil.command(
    "buildogram",
    "Serve buildogram SVGs on request.",
    args,
  )

  let port = get_env("PORT", int.parse, 3000)
  use port, cmd <- opt.int_(cmd, "port", Some("p"), "Port to listen on", port)

  let cache_size = get_env("BUILDOGRAM_CACHE_SIZE", int.parse, 100)
  use cache_size, cmd <- opt.int(cmd, "cache", "HTTP cache size", cache_size)

  try port = port(cmd)
  try cache_size = cache_size(cmd)

  // TODO: use supervisor
  // Start our dependencies
  try client =
    http_client.start(cache_size)
    |> cmd_snag("starting HTTP client")

  // Start the web server process
  try server =
    http_server.stack(client)
    |> cmd_result()
  try _ =
    elli.start(server, on_port: port)
    |> cmd_snag("starting HTTP server")

  log("🛠 HTTP cache item limit: " <> int.to_string(cache_size))
  log("✨ Buildogram is now listening on :" <> int.to_string(port))
  log("Use Ctrl+C, Ctrl+C to stop.")

  // TODO: signal handling
  Ok(process.sleep_forever())
}

pub fn main() {
  erlang.start_arguments()
  |> main_cmd()
  |> result.map_error(print_usage_and_exit)
}

fn cmd_snag(res: Result(a, b), context: String) -> CommandResult(a, Snag) {
  result.map_error(res, fn(_) { CommandError(snag.new(context)) })
}

fn cmd_result(res: Result(a, b)) -> CommandResult(a, b) {
  result.map_error(res, fn(e) { CommandError(e) })
}
