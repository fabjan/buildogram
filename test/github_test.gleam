import gleeunit/should
import gleam/json
import gleam/option.{None, Some}
import gleam/uri
import buildogram/github.{WorkflowJobRun, WorkflowRun}
import buildogram/timestamp.{Timestamp}

pub fn decode_run_test() {
  let input_json =
    "{
       \"id\": 3505370706,
       \"run_number\": 21,
       \"workflow_id\": 40609520,
       \"check_suite_id\": 9401904786,
       \"run_attempt\": 1,
       \"previous_attempt_url\": null,
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

  try expect_html_url =
    uri.parse("https://github.com/fabjan/poopline/actions/runs/3505370706")

  try expect_jobs_url =
    uri.parse(
      "https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706/jobs",
    )

  let expected =
    WorkflowRun(
      name: "CI",
      html_url: expect_html_url,
      head_branch: "main",
      run_number: 21,
      previous_attempt_url: None,
      conclusion: Some("success"),
      run_started_at: Timestamp(2022, 11, 19, 22, 16, 57),
      updated_at: Timestamp(2022, 11, 19, 22, 17, 16),
      jobs_url: expect_jobs_url,
    )

  Ok(
    json.decode(input_json, github.decode_run)
    |> should.equal(Ok(expected)),
  )
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

  try expect_html_url =
    uri.parse(
      "https://github.com/fabjan/poopline/actions/runs/3505370706/jobs/5871644545",
    )

  let expected =
    WorkflowJobRun(
      name: "inception",
      run_attempt: 1,
      html_url: expect_html_url,
      status: "completed",
      conclusion: Some("success"),
      started_at: Timestamp(2022, 11, 19, 22, 17, 5),
      completed_at: Timestamp(2022, 11, 19, 22, 17, 14),
    )

  Ok(
    json.decode(input_json, github.decode_job_run)
    |> should.equal(Ok(expected)),
  )
}

pub fn decode_in_progress_test() {
  let input_json =
    "{
       \"name\": \"CI\",
       \"head_branch\": \"main\",
       \"run_number\": 21,
       \"previous_attempt_url\": null,
       \"conclusion\": null,
       \"html_url\": \"https://github.com/fabjan/poopline/actions/runs/3505370706\",
       \"run_started_at\": \"2022-11-19T22:16:57Z\",
       \"updated_at\": \"2022-11-19T22:17:16Z\",
       \"jobs_url\": \"https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706/jobs\"
    }"

  try expect_html_url =
    uri.parse("https://github.com/fabjan/poopline/actions/runs/3505370706")

  try expect_jobs_url =
    uri.parse(
      "https://api.github.com/repos/fabjan/poopline/actions/runs/3505370706/jobs",
    )

  let expected =
    WorkflowRun(
      name: "CI",
      html_url: expect_html_url,
      head_branch: "main",
      run_number: 21,
      previous_attempt_url: None,
      conclusion: None,
      run_started_at: Timestamp(2022, 11, 19, 22, 16, 57),
      updated_at: Timestamp(2022, 11, 19, 22, 17, 16),
      jobs_url: expect_jobs_url,
    )

  Ok(
    json.decode(input_json, github.decode_run)
    |> should.equal(Ok(expected)),
  )
}
