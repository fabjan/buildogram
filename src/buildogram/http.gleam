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

import gleam/bit_builder.{BitBuilder, append_string}
import gleam/io
import gleam/string
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import snag.{Snag}
import buildogram/github
import buildogram/diagram

/// Configure middleware etc.
pub fn stack() -> fn(Request(BitString)) -> Response(BitBuilder) {
  routes
  |> snag_handler(bit_builder.from_string)
}

/// This is the main entry point for the web server.
pub fn routes(request) -> Result(Response(BitBuilder), Snag) {
  let path = request.path_segments(request)

  case request.method, path {
    Get, ["hello", whom] -> hello(whom)
    Get, ["bars", owner, repo] -> handle_get_svg(owner, repo)
    Get, ["debug", "backfill", owner, repo] -> handle_backfill(owner, repo)
    _, _ -> not_found()
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

fn handle_backfill(owner, repo) {
  let repo_path = string.concat([owner, "/", repo])

  // TODO: completed runs should be cached in a worker process, and/or the file system
  try runs = github.get_all_runs(repo_path)

  let response_body =
    bit_builder.new()
    |> append_string("<h1> Debugging </h1>\n")
    |> append_string("<h2> Inline SVG </h2>\n")
    |> append_string(diagram.bar_chart(runs, 600, 100))
    |> append_string("<h2> SVG as an image </h2>\n")
    |> append_string(
      "<img src=\"http://localhost:3000/bars/" <> owner <> "/" <> repo <> "/\" />\n",
    )

  let content_type = "text/html"

  let resp =
    response.new(200)
    |> response.set_body(response_body)
    |> response.prepend_header("content-type", content_type)

  Ok(resp)
}

fn handle_get_svg(owner, repo) {
  let repo_path = string.concat([owner, "/", repo])

  try runs = github.get_all_runs(repo_path)

  let content_type = "image/svg+xml"
  let response_body = diagram.bar_chart(runs, 400, 100)

  Ok(
    response.new(200)
    |> response.set_body(bit_builder.from_string(response_body))
    |> response.prepend_header("content-type", content_type),
  )
}

fn snag_handler(
  before: fn(Request(a)) -> Result(Response(b), Snag),
  body_builder: fn(String) -> b,
) -> fn(Request(a)) -> Response(b) {
  fn(x: Request(a)) {
    case before(x) {
      Ok(response) -> response
      Error(s) -> {
        io.println(line_print(x) <> " " <> snag.line_print(s))
        response.new(500)
        |> response.set_body(body_builder("Internal Server Error"))
      }
    }
  }
}

pub fn line_print(req: Request(a)) -> String {
  case req.method {
    http.Connect -> "CONNECT"
    http.Delete -> "DELETE"
    http.Get -> "GET"
    http.Head -> "HEAD"
    http.Options -> "OPTIONS"
    http.Patch -> "PATCH"
    http.Post -> "POST"
    http.Put -> "PUT"
    http.Trace -> "TRACE"
    http.Other(m) -> string.uppercase(m)
  }
  |> string.append(" ")
  |> string.append(req.path)
}
