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
import gleam/option.{Some}
import gleam/string_builder

pub fn doc(sb, width, height, elements) {
  let add = string_builder.append

  sb
  |> add("<svg")
  |> attr("xmlns", "http://www.w3.org/2000/svg")
  |> intattr("width", width)
  |> intattr("height", height)
  |> add(">")
  |> string_builder.append_builder(string_builder.concat(elements))
  |> add("</svg>")
}

pub fn text(sb, text, x, y, text_size) {
  let add = string_builder.append

  sb
  |> add("<text")
  |> intattr(" x", x)
  |> intattr(" y", y)
  |> intattr(" font-size", text_size)
  |> attr(" font-family", "sans-serif")
  |> attr(" fill", "black")
  |> add(">")
  |> add(text)
  |> add("</text>")
}

pub fn rect(sb, x, y, width, height, fill, on_click) {
  let add = string_builder.append

  sb
  |> add("<rect")
  |> intattr(" x", x)
  |> intattr(" y", y)
  |> intattr(" width", width)
  |> intattr(" height", height)
  |> attr(" fill", fill)
  |> attr("onclick", on_click)
  |> add("/>")
}

pub fn line(sb, x1, y1, x2, y2, stroke, dasharray) {
  let add = string_builder.append

  sb
  |> add("<line")
  |> intattr(" x1", x1)
  |> intattr(" y1", y1)
  |> intattr(" x2", x2)
  |> intattr(" y2", y2)
  |> attr(" stroke", stroke)
  |> fn(sb) {
    case dasharray {
      Some(dasharray) -> attr(sb, "stroke-dasharray", dasharray)
      _ -> sb
    }
  }
  |> add("/>")
}

fn add_strings(sb, s) {
  sb
  |> string_builder.append_builder(string_builder.from_strings(s))
}

fn attr(sb, key, value) {
  sb
  |> add_strings([" ", key, "=\"", value, "\""])
}

fn intattr(sb, key, value) {
  sb
  |> add_strings([" ", key, "=\"", int.to_string(value), "\""])
}
