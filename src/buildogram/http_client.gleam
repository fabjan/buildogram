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

import gleam/erlang/process.{Subject}
import gleam/hackney
import gleam/http.{Get}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/int
import gleam/io
import gleam/option
import gleam/map.{Map}
import gleam/otp/actor.{StartError}
import gleam/result
import gleam/uri.{Uri}
import snag.{Snag}
import buildogram/util

pub type HttpGet {
  HttpGet(
    host: String,
    path: String,
    respond: Subject(Result(Response(String), Snag)),
  )
}

pub fn new_get(
  uri: Uri,
  respond: Subject(Result(Response(String), Snag)),
) -> Result(HttpGet, Snag) {
  let Uri(_, _, host, _, path, _, _) = uri
  try host = option.to_result(host, snag.new("no host"))
  Ok(HttpGet(host, path, respond))
}

pub fn start() -> Result(Subject(HttpGet), StartError) {
  actor.start(HttpClient(map.new(), map.new()), handle_get)
}

type HttpClient {
  HttpClient(etags: Map(String, String), cache: Map(String, Response(String)))
}

fn handle_get(get: HttpGet, state: HttpClient) -> actor.Next(HttpClient) {
  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host(get.host)
    |> request.set_path(get.path)

  // this is not general, but works for our GitHub API requests
  let cache_key = req.path

  let response = case map.get(state.etags, cache_key) {
    // if we have seen an etag for this request, add it for conditional GET
    Ok(etag) ->
      req
      |> request.prepend_header("If-None-Match", etag)
      |> hackney_send()
    // otherwise, just send the request
    Error(Nil) -> hackney_send(req)
  }

  case response {
    Ok(resp) ->
      case resp.status {
        304 -> {
          let resp = case map.get(state.cache, cache_key) {
            Ok(resp) -> resp
            Error(Nil) -> resp
          }
          process.send(get.respond, Ok(resp))
          actor.Continue(state)
        }
        200 -> {
          let etag = response.get_header(resp, "etag")
          io.println(
            util.show_req(req) <> " 200 OK, caching with etag=" <> result.unwrap(
              etag,
              "<none>",
            ),
          )
          let etags = case response.get_header(resp, "etag") {
            Ok(etag) -> map.insert(state.etags, cache_key, etag)
            Error(Nil) -> state.etags
          }
          let cache = map.insert(state.cache, cache_key, resp)
          process.send(get.respond, Ok(resp))
          actor.Continue(HttpClient(etags, cache))
        }
        _ -> {
          process.send(get.respond, snag.error("nope"))
          actor.Continue(state)
        }
      }
    Error(err) -> {
      process.send(get.respond, Error(err))
      actor.Continue(state)
    }
  }
}

fn hackney_send(req: Request(String)) -> Result(Response(String), Snag) {
  req
  |> request.prepend_header("User-Agent", "buildogram")
  |> hackney.send()
  |> snagmap_hackney()
}

fn snagmap_hackney(
  res: Result(Response(String), hackney.Error),
) -> Result(Response(String), Snag) {
  case res {
    Ok(rep) ->
      case rep.status {
        200 -> Ok(rep)
        304 -> Ok(rep)
        status -> snag.error("response status: " <> int.to_string(status))
      }
    Error(_) -> snag.error("hackney error")
  }
}
