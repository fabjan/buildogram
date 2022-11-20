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

import gleam/bit_builder
import gleam/bit_string
import gleam/int
import gleam/string
import gleam/http.{Get}
import gleam/http/service
import gleam/http/request
import gleam/http/response
//import gleam/json
import gleam/list
import buildogram/backfill
import buildogram/github.{WorkflowRun}
import buildogram/util

/// Configure middleware etc.
pub fn stack() {
  routes
  |> service.map_response_body(bit_builder.from_bit_string)
}

/// This is the main entry point for the web server.
pub fn routes(request) {
  let path = request.path_segments(request)

  case request.method, path {
    Get, ["hello", whom] -> hello(whom)
    Get, ["debug", "backfill_workflow_runs", owner, repo] ->
      handle_backfill_runs(owner, repo)
    _, _ -> not_found()
  }
}

fn not_found() {
  let body =
    "not found"
    |> bit_string.from_string

  response.new(404)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/plain")
}

fn hello(whom) {
  let reply = string.concat(["Hello, ", whom, "!"])

  response.new(200)
  |> response.set_body(bit_string.from_string(reply))
  |> response.prepend_header("content-type", "text/plain")
}

fn handle_backfill_runs(owner, repo) {
  let repo_path = string.concat([owner, "/", repo])

  // TODO: completed runs should be cached in a worker process, and/or the file system
  let runs = backfill.get_all_runs(repo_path)

  // TODO: use bit_builder for reals
  let link = fn(text: String, href: String) {
    string.concat(["<a href=\"", href, "\">", text, "</a>"])
  }
  let run_summary = fn(run: WorkflowRun) {
    string.concat([
      link(run.name, run.html_url),
      " ",
      run.conclusion,
      " (",
      util.time_diff(run.run_started_at, run.updated_at)
      |> int.to_string(),
      "s)",
    ])
  }

  let response_body =
    string.concat([
      "<html><body><ul><li>",
      runs
      |> list.map(run_summary)
      |> string.join("</li>\n<li>"),
      "</li></ul></body></html>",
    ])

  let content_type = "text/html"

  //let response_body =
  //  runs
  //  |> json.array(github.encode_run)
  //  |> json.to_string
  response.new(200)
  |> response.set_body(bit_string.from_string(response_body))
  |> response.prepend_header("content-type", content_type)
}
