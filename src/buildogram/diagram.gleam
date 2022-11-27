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

  let max_runtime =
    grouped_runs
    |> list.map(fn(r) { util.sum(list.map(r, runtime_seconds)) })
    |> util.max(0)

  let bar_height = fn(run) { runtime_seconds(run) * max_height / max_runtime }

  let make_bar = fn(bar_x: Int, bar_y: Int, run: github.WorkflowRun) -> String {
    let bar_height = bar_height(run)
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
        #(bar_y + bar_height(run) + 1, sb)
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

  let grid_etc =
    string_builder.new()
    |> append("<g>")
    |> append("<line ")
    |> append(make_intattr(" x1", 0))
    |> append(make_intattr(" y1", 0))
    |> append(make_intattr(" x2", 0))
    |> append(make_intattr(" y2", height))
    |> append(make_attr(" stroke", "black"))
    |> append("/>")
    // cross at max_height
    |> append("<line ")
    |> append(make_intattr(" x1", 0))
    |> append(make_intattr(" y1", height - max_height))
    |> append(make_intattr(" x2", width))
    |> append(make_intattr(" y2", height - max_height))
    |> append(make_attr(" stroke", "black"))
    |> append(make_attr(" stroke-dasharray", "5,5"))
    |> append("/>")
    // max time label at top
    |> axis_label(int.to_string(max_runtime) <> "s", text_size)
    // zero time label at bottom
    |> axis_label("0s", height)
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
