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
import gleam/json
import gleam/list
import gleam/option.{Option}
import gleam/string
import gleam/dynamic

/// The sum of all Ints in the given list.
pub fn sum(l: List(Int)) -> Int {
  list.fold(l, 0, fn(a, b) { a + b })
}

/// The median of all Ints in the given list.
pub fn median(l: List(Int)) -> Option(Int) {
  let sorted = list.sort(l, int.compare)
  let length = list.length(sorted)
  let middle = length / 2

  sorted
  |> list.at(middle)
  |> option.from_result()
}

/// The greatest Int in the given list.
pub fn max(l: List(Int), z: Int) -> Int {
  list.fold(
    l,
    z,
    fn(a, b) {
      case a > b {
        True -> a
        False -> b
      }
    },
  )
}

/// String description of a JSON decode error.
pub fn json_issue(err: json.DecodeError) -> String {
  case err {
    json.UnexpectedEndOfInput -> "unexpected end of input"
    json.UnexpectedByte(byte, pos) ->
      "unexpected byte " <> byte <> " at: " <> int.to_string(pos)
    json.UnexpectedSequence(byte, pos) ->
      "unexpected sequence " <> byte <> " at: " <> int.to_string(pos)
    json.UnexpectedFormat(errors) ->
      "unexpected format: " <> string.join(list.map(errors, dynamic_issue), ",")
  }
}

/// String description of a dynamic decode error.
pub fn dynamic_issue(err: dynamic.DecodeError) -> String {
  "expected: " <> err.expected <> " found: " <> err.found <> " at: " <> string.join(
    err.path,
    "/",
  )
}
