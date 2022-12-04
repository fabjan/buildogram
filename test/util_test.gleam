import gleeunit/should
import gleam/option.{None, Some}
import buildogram/util

pub fn sum_test() {
  let input = []
  util.sum(input)
  |> should.equal(0)

  let input = [1, 2, 3]
  util.sum(input)
  |> should.equal(6)
}

pub fn max_test() {
  let input = []
  util.max(input, -1)
  |> should.equal(-1)

  let input = [1, 2, 3]
  util.max(input, 0)
  |> should.equal(3)
}

pub fn median_test() {
  let input = []
  util.median(input)
  |> should.equal(None)

  let input = [5]
  util.median(input)
  |> should.equal(Some(5))

  let input = [1, 2, 3]
  util.median(input)
  |> should.equal(Some(2))

  let input = [1, 2, 3, 4]
  util.median(input)
  |> should.equal(Some(3))

  let input = [1, 5, 3, 1, 1]
  util.median(input)
  |> should.equal(Some(1))
}
