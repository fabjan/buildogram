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
import gleam/json
import gleam/hackney
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{Option}
import gleam/result
import gleam/uri.{Uri}
import snag.{Snag}
import buildogram/timestamp.{Timestamp, decode_timestamp}
import buildogram/util

/// WorkflowRun is a full pipeline run.
pub type WorkflowRun {
  WorkflowRun(
    name: String,
    head_branch: String,
    run_number: Int,
    previous_attempt_url: Option(Uri),
    conclusion: String,
    html_url: Uri,
    run_started_at: Timestamp,
    updated_at: Timestamp,
    jobs_url: Uri,
  )
}

/// WorkflowJobRun is a run of a single job in a pipeline.
pub type WorkflowJobRun {
  WorkflowJobRun(
    name: String,
    html_url: Uri,
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

  try runs =
    request
    |> get_and_decode(dynamic.field("workflow_runs", dynamic.list(decode_run)))

  try all_runs = collect_previous_attempts(runs, 5)

  Ok(all_runs)
}

fn collect_previous_attempts(
  runs: List(WorkflowRun),
  max_depth: Int,
) -> Result(List(WorkflowRun), Snag) {
  case max_depth {
    0 -> {
      io.println("Max depth reached, can't get all previous attempts")
      Ok(runs)
    }
    _ ->
      case previous_run_urls(runs) {
        [] -> Ok(runs)
        urls -> {
          try prevs = result.all(previous_attempts(urls))
          collect_previous_attempts(prevs, max_depth - 1)
          |> result.map(fn(prevprev) {
            prevprev
            |> list.append(prevs)
            |> list.append(runs)
          })
        }
      }
  }
}

fn previous_run_urls(runs: List(WorkflowRun)) -> List(Uri) {
  runs
  |> list.filter_map(fn(run) { option.to_result(run.previous_attempt_url, Nil) })
}

fn previous_attempts(run_urls: List(Uri)) -> List(Result(WorkflowRun, Snag)) {
  let get_run = fn(url) -> Result(WorkflowRun, Snag) {
    try req =
      request.from_uri(url)
      |> snag_context("failed to create request")

    try run =
      get_and_decode(req, decode_run)
      |> snag_context("failed to get run")

    Ok(run)
  }

  list.map(run_urls, get_run)
}

fn hackney_send(req: Request(String)) -> Result(Response(String), Snag) {
  req
  |> request.prepend_header("User-Agent", "buildogram")
  |> hackney.send()
  |> snagmap_hackney()
}

fn get_and_decode(
  req: Request(String),
  decode: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
) -> Result(a, Snag) {
  try response =
    hackney_send(req)
    |> snag.context("HTTP request failed")
  try previous_run =
    response.body
    |> json.decode(decode)
    |> snagmap_json()
    |> snag.context("JSON decode failed")
  Ok(previous_run)
}

fn dynamic_uri(dyn: Dynamic) -> Result(Uri, List(DecodeError)) {
  case dynamic.string(dyn) {
    Error(errs) -> Error(errs)
    Ok(uri) ->
      case uri.parse(uri) {
        Error(_) -> Error([dynamic.DecodeError("valid URI", uri, [])])
        Ok(uri) -> Ok(uri)
      }
  }
}

pub fn decode_run(dyn: Dynamic) -> Result(WorkflowRun, List(DecodeError)) {
  dynamic.decode9(
    WorkflowRun,
    dynamic.field("name", dynamic.string),
    dynamic.field("head_branch", dynamic.string),
    dynamic.field("run_number", dynamic.int),
    dynamic.field("previous_attempt_url", dynamic.optional(dynamic_uri)),
    dynamic.field("conclusion", dynamic.string),
    dynamic.field("html_url", dynamic_uri),
    dynamic.field("run_started_at", decode_timestamp),
    dynamic.field("updated_at", decode_timestamp),
    dynamic.field("jobs_url", dynamic_uri),
  )(
    dyn,
  )
}

pub fn decode_job_run(dyn: Dynamic) -> Result(WorkflowJobRun, List(DecodeError)) {
  dynamic.decode7(
    WorkflowJobRun,
    dynamic.field("name", dynamic.string),
    dynamic.field("html_url", dynamic_uri),
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

fn snag_context(res: Result(a, b), msg: String) -> Result(a, Snag) {
  result.map_error(res, fn(_) { snag.new(msg) })
}
