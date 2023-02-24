import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Option, Some}
import gleam/regex
import gleam/string
import gleam/uri.{Uri}
import gleeunit/should
import buildogram/github.{WorkflowRun}
import buildogram/diagram
import buildogram/timestamp.{Timestamp}

pub fn one_run_test() {
  let runs = [[fake_run(0, 5, "success", None)]]

  let diagram = diagram.bar_chart(runs, 1, 1)

  // each run yields a rect in the SVG
  count_rects(diagram)
  |> should.equal(1)
}

pub fn multi_attempt_run_test() {
  let runs = [
    [fake_run(10, 15, "failure", None), fake_run(20, 25, "success", None)],
  ]

  let diagram = diagram.bar_chart(runs, 1, 1)

  // each run yields a rect in the SVG
  count_rects(diagram)
  |> should.equal(2)
}

pub fn many_runs_test() {
  let runs = [
    [fake_run(0, 5, "success", None)],
    [
      fake_run(10, 15, "failure", None),
      fake_run(20, 25, "success", Some("http://example.com")),
    ],
    [
      fake_run(110, 115, "failure", None),
      fake_run(120, 125, "success", Some("http://example.com")),
    ],
    [
      fake_run(210, 215, "failure", None),
      fake_run(220, 225, "failure", Some("http://example.com")),
      fake_run(230, 235, "success", Some("http://example.com")),
    ],
    [
      fake_run(310, 315, "failure", None),
      fake_run(320, 325, "failure", Some("http://example.com")),
      fake_run(330, 335, "success", Some("http://example.com")),
    ],
    [fake_run(400, 405, "success", None)],
    [fake_run(500, 505, "success", None)],
    [fake_run(600, 605, "success", None)],
    [fake_run(700, 705, "success", None)],
  ]

  let diagram = diagram.bar_chart(runs, 1, 1)

  // each run yields a rect in the SVG
  count_rects(diagram)
  |> should.equal(15)
}

pub fn unexpected_conclusion_test() {
  io.println_error("Heads up: this test will print to stderr!")

  let runs = [
    [fake_run(0, 5, "unexpected", None)],
    [fake_run(0, 5, "wjin beof8y23bu", None)],
  ]

  let diagram = diagram.bar_chart(runs, 1, 1)

  // each run yields a rect in the SVG
  count_rects(diagram)
  |> should.equal(2)

  string.starts_with(diagram, "<svg")
  |> should.be_true()
}

pub fn empty_runs_test() {
  let runs = []

  let diagram = diagram.bar_chart(runs, 1, 1)

  // each run yields a rect in the SVG
  count_rects(diagram)
  |> should.equal(0)

  string.starts_with(diagram, "<svg")
  |> should.be_true()
}

fn count_rects(s: String) -> Int {
  assert Ok(re) = regex.from_string("<rect")
  regex.scan(re, s)
  |> list.length
}

fn ts(seconds) -> Timestamp {
  Timestamp(2038, 01, 01, 00, 00, seconds)
}

fn fake_run(
  started_at_s: Int,
  updated_at_s: Int,
  conclusion: String,
  previous: Option(String),
) -> WorkflowRun {
  WorkflowRun(
    name: "Continuous Integration",
    head_branch: "main",
    run_number: int.random(1, 10_000),
    previous_attempt_url: option.map(previous, must_parse),
    conclusion: Some(conclusion),
    html_url: must_parse("http://example.com"),
    run_started_at: ts(started_at_s),
    updated_at: ts(updated_at_s),
    jobs_url: must_parse("http://example.com"),
  )
}

fn must_parse(s: String) -> Uri {
  assert Ok(url) = uri.parse(s)
  url
}
