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
import gleam/otp/actor.{StartError}
import gleam/string
import gleam/uri.{Uri}
import snag.{Snag}
import buildogram/cache.{Cache}

const request_timeout = 10000

pub type HttpGet {
  HttpGet(
    host: String,
    path: String,
    respond: Subject(Result(Response(String), Snag)),
  )
}

/// Start a new HTTP client.
pub fn start(cache_size: Int) -> Result(Subject(HttpGet), StartError) {
  let lru = cache.lru(cache_size, cache.default_timestamp)
  actor.start(HttpClient(lru), handle_get)
}

/// Send a GET request to the given host/path, via client.
pub fn get(client, host, path) -> Result(Response(String), Snag) {
  let pipe = process.new_subject()
  let req = HttpGet(host, path, pipe)

  process.send(client, req)

  // FIXME: this is not a flatmap...
  case process.receive(pipe, request_timeout) {
    Ok(Ok(response)) -> Ok(response)
    Ok(Error(snag)) -> Error(snag)
    Error(_) -> snag.error("timeout waiting for response")
  }
}

/// Send a GET request to the given URL, via client.
pub fn get_url(client, url) -> Result(Response(String), Snag) {
  let pipe = process.new_subject()
  try req = new_get(url, pipe)

  process.send(client, req)

  // FIXME: this is not a flatmap...
  case process.receive(pipe, request_timeout) {
    Ok(Ok(response)) -> Ok(response)
    Ok(Error(snag)) -> Error(snag)
    Error(_) -> snag.error("timeout waiting for response")
  }
}

fn new_get(
  uri: Uri,
  respond: Subject(Result(Response(String), Snag)),
) -> Result(HttpGet, Snag) {
  let Uri(_, _, host, _, path, _, _) = uri
  try host = option.to_result(host, snag.new("no host"))
  Ok(HttpGet(host, path, respond))
}

type CachedResponse {
  CachedResponse(response: Response(String), etag: String)
}

type HttpClient {
  HttpClient(cache: Cache(CachedResponse))
}

fn log(s) {
  io.println("[http_client] " <> s)
}

fn handle_get(get: HttpGet, state: HttpClient) -> actor.Next(HttpClient) {
  let req =
    request.new()
    |> request.set_method(Get)
    |> request.set_host(get.host)
    |> request.set_path(get.path)

  // this is not general, but works for our GitHub API requests
  let cache_key = req.path

  let #(cache, cached_resp) = cache.get(state.cache, cache_key)

  let #(cache, resp) = case cached_resp {
    Error(Nil) ->
      case hackney_send(req) {
        Error(snag) -> #(cache, Error(snag))
        Ok(resp) -> refill(cache, cache_key, resp)
      }
    Ok(cached) -> {
      let CachedResponse(old_resp, etag) = cached
      case hackney_send(request.set_header(req, "If-None-Match", etag)) {
        Error(snag) -> #(cache, Error(snag))
        Ok(new_resp) ->
          case new_resp.status {
            304 -> #(cache, Ok(old_resp))
            _ -> refill(cache, cache_key, new_resp)
          }
      }
    }
  }

  process.send(get.respond, resp)
  actor.Continue(HttpClient(cache))
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
        status -> {
          let issue = "response status: " <> int.to_string(status)
          log(issue)
          snag.error(issue)
        }
      }
    Error(_) -> {
      let issue = "hackney error"
      log(issue)
      snag.error(issue)
    }
  }
}

fn refill(
  c: Cache(CachedResponse),
  key: String,
  resp: Response(String),
) -> #(Cache(CachedResponse), Result(Response(String), Snag)) {
  let status = resp.status
  case response.get_header(resp, "etag") {
    Ok(etag) if status == 200 -> {
      log("GET " <> key <> " 200, refilling cache")
      let c = cache.set(c, key, CachedResponse(resp, etag))
      log("keys in cache: " <> string.join(cache.keys(c), " "))
      #(c, Ok(resp))
    }
    _ -> #(c, Ok(resp))
  }
}
