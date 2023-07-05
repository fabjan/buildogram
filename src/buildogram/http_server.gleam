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

import gleam/result
import gleam/base
import gleam/bit_builder.{BitBuilder}
import gleam/erlang/atom.{Atom}
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/io
import gleam/erlang/process.{Subject}
import gleam/string
import snag.{Snag}
import buildogram/diagram
import buildogram/github
import buildogram/http_client.{HttpGet}
import buildogram/util

fn log(s) {
  io.println_error("[http_server] " <> s)
}

/// Configure middleware etc.
pub fn stack(
  client: Subject(HttpGet),
) -> Result(fn(Request(BitString)) -> Response(BitBuilder), Snag) {
  Ok(
    routes(client)
    |> snag_handler(bit_builder.from_string),
  )
}

/// This is the main entry point for the web server.
pub fn routes(
  client: Subject(HttpGet),
) -> fn(Request(a)) -> Result(Response(BitBuilder), Snag) {
  fn(req) {
    let path = request.path_segments(req)

    case req.method, path {
      Get, ["hello", whom] -> hello(whom)
      Get, ["bars", owner, repo] -> handle_get_svg(client, owner, repo)
      _, _ -> not_found()
    }
  }
}

fn not_found() {
  let body =
    "not found"
    |> bit_builder.from_string

  Ok(
    response.new(404)
    |> response.set_body(body)
    |> response.prepend_header("content-type", "text/plain"),
  )
}

fn hello(whom) {
  let reply = string.concat(["Hello, ", whom, "!"])

  Ok(
    response.new(200)
    |> response.set_body(bit_builder.from_string(reply))
    |> response.prepend_header("content-type", "text/plain"),
  )
}

fn handle_get_svg(client, owner, repo) {
  let repo_path = string.concat([owner, "/", repo])

  use runs <- result.then(github.get_all_runs(client, repo_path))

  let response_body = diagram.bar_chart(runs, 400, 100)

  let resp =
    response.new(200)
    |> response.prepend_header("content-type", "image/svg+xml")
    // By adding no-cache and etag headers we can inform proxies and browsers
    // that they should not cache the response.
    |> response.prepend_header("etag", "W/\"" <> md5(response_body) <> "\"")
    |> response.prepend_header("cache-control", "no-cache")

  let resp =
    resp
    |> response.set_body(bit_builder.from_string(response_body))

  Ok(resp)
}

fn snag_handler(
  before: fn(Request(a)) -> Result(Response(b), Snag),
  body_builder: fn(String) -> b,
) -> fn(Request(a)) -> Response(b) {
  fn(x: Request(a)) {
    case before(x) {
      Ok(response) -> response
      Error(s) -> {
        log(util.show_request(x) <> " " <> snag.line_print(s))
        response.new(500)
        |> response.set_body(body_builder("Internal Server Error"))
      }
    }
  }
}

fn md5(data: String) -> String {
  let algo = atom.create_from_string("md5")
  let digest = hash(algo, data)
  base.encode64(digest, True)
}

@external(erlang, "crypto", "hash")
fn hash(algo algo: Atom, data data: String) -> BitString
