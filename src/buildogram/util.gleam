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
import gleam/string
import gleam/dynamic.{DecodeError, Dynamic}
import gleam/result

/// Something went wrong parsing something.
pub type ParseError {
  ParseError(issue: String)
}

/// A timestamp (in UTC)
pub type Timestamp {
  Timestamp(
    year: Int,
    month: Int,
    day: Int,
    hour: Int,
    minute: Int,
    second: Int,
  )
}

/// The difference in seconds between two timestamps.
pub fn time_diff(start: Timestamp, end: Timestamp) -> Int {
  to_seconds(end) - to_seconds(start)
}

/// Parse Timestamps from a subset of ISO 8601.
pub fn parse_iso_8601(date: String) -> Result(Timestamp, ParseError) {
  let split = string.split

  // TODO: handle these cases without match errors
  let [datestring, timestring] = split(date, "T")
  let [year, month, day] = split(datestring, "-")
  let [hour, minute, second] = split(timestring, ":")
  let [second, _] = split(second, "Z")

  try year = parse_int(year, "year")
  try month = parse_int(month, "month")
  try day = parse_int(day, "day")
  try hour = parse_int(hour, "hour")
  try minute = parse_int(minute, "minute")
  try second = parse_int(second, "second")
  Ok(Timestamp(year, month, day, hour, minute, second))
}

/// Decode a Timestamp from a Dynamic value.
pub fn decode_timestamp(value: Dynamic) -> Result(Timestamp, List(DecodeError)) {
  try s = dynamic.string(value)
  parse_iso_8601(s)
  |> result.map_error(fn(e) {
    [DecodeError(expected: "ISO 8601", found: e.issue, path: [])]
  })
}

/// Encode a Timestamp to a String.
pub fn encode_timestamp(timestamp: Timestamp) -> String {
  let year = int.to_string(timestamp.year)
  let month = int.to_string(timestamp.month)
  let day = int.to_string(timestamp.day)
  let hour = int.to_string(timestamp.hour)
  let minute = int.to_string(timestamp.minute)
  let second = int.to_string(timestamp.second)

  let datestring = year <> "-" <> month <> "-" <> day
  let timestring = hour <> ":" <> minute <> ":" <> second <> "Z"
  datestring <> "T" <> timestring
}

fn to_seconds(ts: Timestamp) {
  // TODO: perhaps a timestamp struct was not the right approach
  let Timestamp(year, month, day, hour, minute, second) = ts
  let days = day + month * 30 + year * 365
  let seconds = second + minute * 60 + hour * 60 * 60
  days * 24 * 60 * 60 + seconds
}

fn parse_int(s: String, name: String) -> Result(Int, ParseError) {
  case int.parse(s) {
    Ok(i) -> Ok(i)
    Error(_) -> Error(ParseError("cannot parse " <> name <> " from " <> s))
  }
}
