import gleeunit/should
import buildogram/timestamp.{Timestamp}

pub fn parse_iso_8601_test() {
  let input = "2022-11-15T21:42:37Z"
  let expected = Timestamp(2022, 11, 15, 21, 42, 37)

  timestamp.parse_iso_8601(input)
  |> should.equal(Ok(expected))
}

pub fn time_diff_test() {
  let start = Timestamp(2022, 11, 19, 22, 17, 5)
  let end = Timestamp(2022, 11, 19, 22, 17, 14)

  timestamp.time_diff(start, end)
  |> should.equal(9)
}
