import gleeunit
import gleeunit/should
import gleam/json
import buildogram/github.{WorkflowJobRun, WorkflowRun}
import buildogram/util.{Timestamp}

pub fn main() {
  gleeunit.main()
}

pub fn parse_iso_8601_test() {
  let input = "2022-11-15T21:42:37Z"
  let expected = Timestamp(2022, 11, 15, 21, 42, 37)

  util.parse_iso_8601(input)
  |> should.equal(Ok(expected))
}

pub fn decode_run_test() {
  let input_json =
    "{
       \"id\": 3505370706,
       \"run_number\": 21,
       \"workflow_id\": 40609520,
       \"check_suite_id\": 9401904786,
       \"run_attempt\": 1,
       \"html_url\": \"https://github.com/fabjan/poopline/actions/runs/3505370706\",
       \"name\": \"CI\",
       \"node_id\": \"WFR_kwLOIcSVg87Q77ZS\",
       \"head_branch\": \"main\",
       \"head_sha\": \"67262db5a8832ff0857048adefbbcd727aa88be4\",
       \"path\": \".github/workflows/ci.yml\",
       \"display_title\": \"remove custom run name from ci.yml\",
       \"event\": \"push\",
       \"status\": \"completed\",
       \"conclusion\": \"success\",
       \"check_suite_node_id\": \"CS_kwDOIcSVg88AAAACMGWukg\",
       \"created_at\": \"2022-11-19T22:16:57Z\",
       \"updated_at\": \"2022-11-19T22:17:16Z\",
       \"run_started_at\": \"2022-11-19T22:16:57Z\",
       \"jobs_url\": \"https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706/jobs\"
    }"

  let expected =
    WorkflowRun(
      name: "CI",
      html_url: "https://github.com/fabjan/poopline/actions/runs/3505370706",
      head_branch: "main",
      run_number: 21,
      run_attempt: 1,
      conclusion: "success",
      run_started_at: Timestamp(2022, 11, 19, 22, 16, 57),
      updated_at: Timestamp(2022, 11, 19, 22, 17, 16),
      jobs_url: "https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706/jobs",
    )

  json.decode(input_json, github.decode_run)
  |> should.equal(Ok(expected))
}

pub fn decode_job_run_test() {
  let input_json =
    "{
      \"id\": 9595182389,
      \"run_id\": 3505370706,
      \"run_url\": \"https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706\",
      \"run_attempt\": 1,
      \"head_sha\": \"67262db5a8832ff0857048adefbbcd727aa88be4\",
      \"url\": \"https://api.github.com/repos/fabjan/poopline/actions/jobs/9595182389\",
      \"html_url\": \"https://github.com/fabjan/poopline/actions/runs/3505370706/jobs/5871644545\",
      \"status\": \"completed\",
      \"conclusion\": \"success\",
      \"started_at\": \"2022-11-19T22:17:05Z\",
      \"completed_at\": \"2022-11-19T22:17:14Z\",
      \"name\": \"inception\"
    }"

  let expected =
    WorkflowJobRun(
      name: "inception",
      run_attempt: 1,
      html_url: "https://github.com/fabjan/poopline/actions/runs/3505370706/jobs/5871644545",
      status: "completed",
      conclusion: "success",
      started_at: Timestamp(2022, 11, 19, 22, 17, 5),
      completed_at: Timestamp(2022, 11, 19, 22, 17, 14),
    )

  json.decode(input_json, github.decode_job_run)
  |> should.equal(Ok(expected))
}

pub fn time_diff_test() {
  let start = Timestamp(2022, 11, 19, 22, 17, 5)
  let end = Timestamp(2022, 11, 19, 22, 17, 14)

  util.time_diff(start, end)
  |> should.equal(9)
}
