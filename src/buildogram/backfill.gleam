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

import gleam/dynamic
import gleam/hackney
import gleam/http.{Get}
import gleam/http/request
import gleam/http/response.{Response}
import gleam/io
import gleam/json
import buildogram/github

fn github_repo_request(repo: String, path: String) {
  request.new()
  |> request.set_method(Get)
  |> request.set_host("api.github.com")
  |> request.set_path("/repos/" <> repo <> path)
}

/// Get all known runs for a given repository.
///
/// TODO: support for branch filter (?branch=xxx)
pub fn get_all_runs(repo: String) -> List(github.WorkflowRun) {
  let request =
    github_repo_request(repo, "/actions/runs")
    |> request.prepend_header("accept", "application/json")

  let decode_runs = fn(response: Response(String)) {
    response.body
    |> json.decode(dynamic.field(
      "workflow_runs",
      dynamic.list(github.decode_run),
    ))
  }

  // TODO: better error handling. snag? normalize & flatmap Result?
  case hackney.send(request) {
    Error(_) -> {
      io.println("hackney error")
      []
    }
    Ok(response) ->
      case decode_runs(response) {
        Error(_) -> {
          io.println("decode error")
          []
        }
        Ok(runs) -> runs
      }
  }
}
