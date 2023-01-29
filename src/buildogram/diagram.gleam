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

import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/pair
import gleam/string_builder
import gleam/uri
import buildogram/github
import buildogram/svg
import buildogram/timestamp
import buildogram/util

fn log(s) {
  io.println("[diagram] " <> s)
}

/// Render an SVG bar chart from the given workflow runs.
///
/// The runs are grouped by pipeline run, and each group of retries is rendered
/// as a stack.
pub fn bar_chart(
  grouped_runs: List(List(github.WorkflowRun)),
  width: Int,
  height: Int,
) -> String {
  let bar_width = 5
  let text_size = 12
  let max_height = height - 10

  let runtime_seconds = fn(run: github.WorkflowRun) {
    timestamp.time_diff(run.run_started_at, run.updated_at)
  }

  // total per workflow
  let max_runtime =
    grouped_runs
    |> list.map(fn(r) { util.sum(list.map(r, runtime_seconds)) })
    |> util.max(0)

  // per attempt
  let median_runtime =
    grouped_runs
    |> list.flatten()
    |> list.map(runtime_seconds)
    |> util.median()
    |> option.unwrap(max_runtime)

  let scale_seconds = fn(secs) { secs * max_height / max_runtime }

  let make_bar = fn(bar_x: Int, bar_y: Int, run: github.WorkflowRun) -> String {
    let bar_height = scale_seconds(runtime_seconds(run))
    let y_offset = height - bar_height
    let bar_color = case run.conclusion {
      Some("success") -> "green"
      Some("failure") -> "red"
      Some("startup_failure") -> "orange"
      None -> "yellow"
      Some(other) -> {
        let run_url = uri.to_string(run.html_url)
        log("Unknown conclusion: " <> other <> " for run " <> run_url)
        "magenta"
      }
    }
    let link = "window.open('" <> uri.to_string(run.html_url) <> "', '_blank')"

    string_builder.new()
    |> svg.rect(bar_x, y_offset - bar_y, bar_width, bar_height, bar_color, link)
    |> string_builder.to_string()
  }

  let make_stack = fn(i: Int, attempts: List(github.WorkflowRun)) {
    attempts
    |> list.fold(
      #(0, string_builder.new()),
      fn(acc, run) {
        let #(bar_y, sb) = acc
        let bar_x = i * { bar_width + 1 }
        let bar = make_bar(bar_x, bar_y, run)

        let sb = string_builder.append(sb, bar)
        #(bar_y + scale_seconds(runtime_seconds(run)) + 1, sb)
      },
    )
    |> pair.second
  }

  let max_height = height - scale_seconds(max_runtime)
  let median_height = height - scale_seconds(median_runtime)
  let time_string = fn(secs) { int.to_string(secs) <> "s" }

  let grid =
    string_builder.new()
    |> string_builder.append("<g>")
    // y axis
    |> svg.line(0, 0, 0, height, "black", None)
    // x axis
    |> svg.line(0, height, width, height, "black", None)
    // max runtime
    |> svg.line(0, max_height, width, max_height, "black", Some("5,5"))
    |> svg.text(time_string(max_runtime), 1, max_height, text_size)
    // median runtime
    |> svg.line(0, median_height, width, median_height, "black", Some("5,5"))
    |> svg.text(time_string(median_runtime), 1, median_height, text_size)
    |> string_builder.append("</g>")

  let bars =
    grouped_runs
    |> list.index_map(make_stack)

  let chart =
    string_builder.new()
    |> svg.doc(width, height, list.append(bars, [grid]))
    |> string_builder.to_string()

  chart
}
