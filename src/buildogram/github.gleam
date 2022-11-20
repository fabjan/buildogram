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
import buildogram/util.{Timestamp, decode_timestamp, encode_timestamp}

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

pub fn encode_run(run: WorkflowRun) -> Json {
  let run_started_at = encode_timestamp(run.run_started_at)
  let updated_at = encode_timestamp(run.updated_at)
  json.object([
    #("name", json.string(run.name)),
    #("head_branch", json.string(run.head_branch)),
    #("run_number", json.int(run.run_number)),
    #("run_attempt", json.int(run.run_attempt)),
    #("conclusion", json.string(run.conclusion)),
    #("html_url", json.string(run.html_url)),
    #("run_started_at", json.string(run_started_at)),
    #("updated_at", json.string(updated_at)),
    #("jobsurl", json.string(run.jobs_url)),
  ])
}

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

pub fn encode_job_run(job_run: WorkflowJobRun) -> Json {
  let started_at = encode_timestamp(job_run.started_at)
  let completed_at = encode_timestamp(job_run.completed_at)
  json.object([
    #("name", json.string(job_run.name)),
    #("run_attempt", json.int(job_run.run_attempt)),
    #("html_url", json.string(job_run.html_url)),
    #("status", json.string(job_run.status)),
    #("conclusion", json.string(job_run.conclusion)),
    #("started_at", json.string(started_at)),
    #("completed_at", json.string(completed_at)),
  ])
}
