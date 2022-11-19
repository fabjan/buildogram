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

import gleam/bit_builder
import gleam/bit_string
import gleam/string
import gleam/http.{Get}
import gleam/http/service
import gleam/http/request
import gleam/http/response

pub fn stack() {
  routes
  |> service.map_response_body(bit_builder.from_bit_string)
}

pub fn routes(request) {
  let path = request.path_segments(request)

  case request.method, path {
    Get, ["hello", whom] -> hello(whom)
    _, _ -> not_found()
  }
}

fn not_found() {
  let body =
    "not found"
    |> bit_string.from_string

  response.new(404)
  |> response.set_body(body)
  |> response.prepend_header("content-type", "text/plain")
}

fn hello(whom) {
  let reply = string.concat(["Hello, ", whom, "!"])

  response.new(200)
  |> response.set_body(bit_string.from_string(reply))
  |> response.prepend_header("content-type", "text/plain")
}
