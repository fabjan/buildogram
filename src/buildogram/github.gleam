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

import gleam/dynamic.{DecodeError, Dynamic}
import gleam/json.{Json}
import gleam/hackney
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/int
import gleam/result
import snag.{Snag}
import buildogram/util.{Timestamp, decode_timestamp, encode_timestamp}

/// WorkflowRun is a full pipeline run.
pub type WorkflowRun {
  WorkflowRun(
    name: String,
    head_branch: String,
    run_number: Int,
    run_attempt: Int,
    conclusion: String,
    html_url: String,
    run_started_at: Timestamp,
    updated_at: Timestamp,
    jobs_url: String,
  )
}

/// WorkflowJobRun is a run of a single job in a pipeline.
pub type WorkflowJobRun {
  WorkflowJobRun(
    name: String,
    html_url: String,
    run_attempt: Int,
    status: String,
    conclusion: String,
    started_at: Timestamp,
    completed_at: Timestamp,
  )
}

/// Get all known runs for a given repository.
///
/// TODO: support for branch filter (?branch=xxx)
pub fn get_all_runs(repo: String) -> Result(List(WorkflowRun), Snag) {
  let request =
    github_repo_request(repo, "/actions/runs")
    |> request.prepend_header("accept", "application/json")

  try response =
    hackney.send(request)
    |> snagmap_hackney()
    |> snag.context("failed to get all runs")

  try runs =
    response.body
    |> json.decode(dynamic.field("workflow_runs", dynamic.list(decode_run)))
    |> snagmap_json()
    |> snag.context("failed to decode response")

  Ok(runs)
}

pub fn decode_run(dyn: Dynamic) -> Result(WorkflowRun, List(DecodeError)) {
  dynamic.decode9(
    WorkflowRun,
    dynamic.field("name", dynamic.string),
    dynamic.field("head_branch", dynamic.string),
    dynamic.field("run_number", dynamic.int),
    dynamic.field("run_attempt", dynamic.int),
    dynamic.field("conclusion", dynamic.string),
    dynamic.field("html_url", dynamic.string),
    dynamic.field("run_started_at", decode_timestamp),
    dynamic.field("updated_at", decode_timestamp),
    dynamic.field("jobs_url", dynamic.string),
  )(
    dyn,
  )
}

pub fn decode_job_run(dyn: Dynamic) -> Result(WorkflowJobRun, List(DecodeError)) {
  dynamic.decode7(
    WorkflowJobRun,
    dynamic.field("name", dynamic.string),
    dynamic.field("html_url", dynamic.string),
    dynamic.field("run_attempt", dynamic.int),
    dynamic.field("status", dynamic.string),
    dynamic.field("conclusion", dynamic.string),
    dynamic.field("started_at", decode_timestamp),
    dynamic.field("completed_at", decode_timestamp),
  )(
    dyn,
  )
}

fn github_repo_request(repo: String, path: String) {
  request.new()
  |> request.set_method(Get)
  |> request.set_host("api.github.com")
  |> request.set_path("/repos/" <> repo <> path)
}

fn snagmap_hackney(
  res: Result(Response(String), hackney.Error),
) -> Result(Response(String), Snag) {
  case res {
    Ok(rep) ->
      case rep.status {
        200 -> Ok(rep)
        status -> snag.error("response status: " <> int.to_string(status))
      }
    Error(_) -> snag.error("hackney error")
  }
}

fn snagmap_json(res: Result(a, json.DecodeError)) -> Result(a, Snag) {
  result.map_error(res, fn(err) { snag.new(util.json_issue(err)) })
}
