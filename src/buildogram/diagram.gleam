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
import gleam/list
import gleam/map
import gleam/option.{None, Some}
import gleam/pair
import gleam/result
import gleam/string
import gleam/string_builder.{append}
import gleam/uri
import buildogram/github
import buildogram/timestamp
import buildogram/util

/// Render an SVG bar chart from the given workflow runs.
pub fn bar_chart(
  runs: List(github.WorkflowRun),
  width: Int,
  height: Int,
) -> String {
  let bar_width = 5
  let text_size = 12
  let max_height = height - 10

  let grouped_runs =
    runs
    |> list.sort(fn(a, b) { int.compare(a.run_number, b.run_number) })
    |> list_group_by(fn(r: github.WorkflowRun) { r.run_number })

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
    runs
    |> list.map(runtime_seconds)
    |> util.median()
    |> option.unwrap(max_runtime)

  let scale_seconds = fn(secs) { secs * max_height / max_runtime }

  let make_bar = fn(bar_x: Int, bar_y: Int, run: github.WorkflowRun) -> String {
    let bar_height = scale_seconds(runtime_seconds(run))
    let y_offset = height - bar_height
    let bar_color = case run.conclusion {
      "success" -> "green"
      "failure" -> "red"
    }

    string.join(
      [
        "<rect",
        make_intattr("x", bar_x),
        make_intattr("y", y_offset - bar_y),
        make_intattr("width", bar_width),
        make_intattr("height", bar_height),
        make_attr("fill", bar_color),
        make_attr(
          "onclick",
          "window.open('" <> uri.to_string(run.html_url) <> "', '_blank')",
        ),
        "/>",
      ],
      " ",
    )
  }

  let make_stack = fn(i: Int, attempts: List(github.WorkflowRun)) -> String {
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
    |> string_builder.to_string()
  }

  let axis_label = fn(sb, text, y) {
    sb
    |> append("<text")
    |> append(make_intattr(" x", 1))
    |> append(make_intattr(" y", y))
    |> append(make_intattr(" font-size", text_size))
    |> append(make_attr(" font-family", "sans-serif"))
    |> append(make_attr(" fill", "black"))
    |> append(">")
    |> append(text)
    |> append("</text>")
  }

  let line = fn(sb, x1, y1, x2, y2, stroke, dasharray) {
    sb
    |> append("<line")
    |> append(make_intattr(" x1", x1))
    |> append(make_intattr(" y1", y1))
    |> append(make_intattr(" x2", x2))
    |> append(make_intattr(" y2", y2))
    |> append(make_attr(" stroke", stroke))
    |> fn(sb) {
      case dasharray {
        Some(dasharray) -> append(sb, make_attr(" stroke-dasharray", dasharray))
        None -> sb
      }
    }
    |> append("/>")
  }

  let max_height = height - scale_seconds(max_runtime)
  let median_height = height - scale_seconds(median_runtime)
  let time_string = fn(secs) { int.to_string(secs) <> "s" }

  let grid_etc =
    string_builder.new()
    |> append("<g>")
    // y axis
    |> line(0, 0, 0, height, "black", None)
    // x axis
    |> line(0, height, width, height, "black", None)
    // max runtime
    |> line(0, max_height, width, max_height, "black", Some("5,5"))
    |> axis_label(time_string(max_runtime), max_height)
    // median runtime
    |> line(0, median_height, width, median_height, "black", Some("5,5"))
    |> axis_label(time_string(median_runtime), median_height)
    |> append("</g>")
    |> string_builder.to_string()

  let chart =
    string.join(
      [
        "<svg",
        make_attr("xmlns", "http://www.w3.org/2000/svg"),
        make_intattr("width", width),
        make_intattr("height", height),
        ">",
        string.join(list.index_map(grouped_runs, make_stack), "\n"),
        grid_etc,
        "</svg>",
      ],
      " ",
    )

  chart
}

fn make_attr(key, value) {
  string.concat([key, "=\"", value, "\""])
}

fn make_intattr(key, value) {
  string.concat([key, "=\"", int.to_string(value), "\""])
}

fn list_group_by(l: List(a), f: fn(a) -> key) -> List(List(a)) {
  l
  |> list.fold(
    map.new(),
    fn(acc, item) {
      let key = f(item)
      let items =
        map.get(acc, key)
        |> result.unwrap([])
      map.insert(acc, key, list.append(items, [item]))
    },
  )
  |> map.values()
}
