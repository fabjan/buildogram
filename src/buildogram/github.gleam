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
import gleam/erlang/process.{Subject}
import gleam/json
import gleam/http/response.{Response}
import gleam/io
import gleam/list
import gleam/option.{Option}
import gleam/result
import gleam/uri.{Uri}
import snag.{Snag}
import buildogram/http_client.{HttpGet}
import buildogram/timestamp.{Timestamp, decode_timestamp}
import buildogram/util

fn log(s) {
  io.println("[github] " <> s)
}

/// WorkflowRun is a full pipeline run.
pub type WorkflowRun {
  WorkflowRun(
    name: String,
    head_branch: String,
    run_number: Int,
    previous_attempt_url: Option(Uri),
    conclusion: Option(String),
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
    conclusion: Option(String),
    started_at: Timestamp,
    completed_at: Timestamp,
  )
}

/// Get all known runs for a given repository.
///
/// TODO: support for branch filter (?branch=xxx)
pub fn get_all_runs(
  client: Subject(HttpGet),
  repo: String,
) -> Result(List(WorkflowRun), Snag) {
  try resp =
    http_client.get(
      client,
      "api.github.com",
      "/repos/" <> repo <> "/actions/runs",
    )

  try runs =
    resp
    |> json_decode(dynamic.field("workflow_runs", dynamic.list(decode_run)))

  try all_runs = collect_previous_attempts(client, runs, 5)

  Ok(all_runs)
}

fn collect_previous_attempts(
  client: Subject(HttpGet),
  runs: List(WorkflowRun),
  max_depth: Int,
) -> Result(List(WorkflowRun), Snag) {
  case max_depth {
    0 -> {
      log("Max depth reached, can't get all previous attempts")
      Ok(runs)
    }
    _ ->
      case previous_run_urls(runs) {
        [] -> Ok(runs)
        urls -> {
          try prevs = result.all(previous_attempts(client, urls))
          collect_previous_attempts(client, prevs, max_depth - 1)
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

fn previous_attempts(
  client: Subject(HttpGet),
  run_urls: List(Uri),
) -> List(Result(WorkflowRun, Snag)) {
  let get_run = fn(run_url) -> Result(WorkflowRun, Snag) {
    try resp = http_client.get_url(client, run_url)

    try run =
      resp
      |> json_decode(decode_run)

    Ok(run)
  }

  list.map(run_urls, get_run)
}

fn json_decode(
  response: Response(String),
  decode: fn(Dynamic) -> Result(a, List(dynamic.DecodeError)),
) -> Result(a, Snag) {
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
    dynamic.field("conclusion", dynamic.optional(dynamic.string)),
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
    dynamic.field("conclusion", dynamic.optional(dynamic.string)),
    dynamic.field("started_at", decode_timestamp),
    dynamic.field("completed_at", decode_timestamp),
  )(
    dyn,
  )
}

fn snagmap_json(res: Result(a, json.DecodeError)) -> Result(a, Snag) {
  result.map_error(res, fn(err) { snag.new(util.json_issue(err)) })
}
