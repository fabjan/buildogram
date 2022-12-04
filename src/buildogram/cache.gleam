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

import gleam/erlang.{Millisecond}
import gleam/int
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Some}
import gleam/result

pub type Timestamp =
  fn() -> Int

/// Returns the current system time as a timestamp.
pub fn default_timestamp() {
  erlang.system_time(Millisecond)
}

/// Cache stores values in memory up to a given size.
/// If a set operation would exceed the size limit, some values will be evicted
/// to make room for the new value.
pub type Cache(a) {
  /// A cache evicting least recently used items first.
  Lru(items: Map(String, a), atime: Map(String, Int), limit: Int, ts: Timestamp)
}

/// Create a new (empty) LRU cache.
/// ts is a function returning a timestamp used for eviction, you can use
/// e.g. `default_timestamp` for this.
pub fn lru(limit: Int, ts: Timestamp) -> Cache(a) {
  Lru(map.new(), map.new(), limit, ts)
}

/// Get an item from the cache, or Error(Nil) if it doesn't exist.
/// Always returns the updated cache (the item's last_accessed time is updated).
pub fn get(from: Cache(a), key: String) -> #(Cache(a), Result(a, Nil)) {
  case map.get(from.items, key) {
    Error(Nil) -> #(from, Error(Nil))
    Ok(value) -> #(touch(from, key, from.ts), Ok(value))
  }
}

/// Set an item in the cache.
pub fn set(in: Cache(a), key: String, value: a) -> Cache(a) {
  let touch_if_new = fn(a) {
    case a {
      None -> -1
      Some(t) -> t
    }
  }

  let in: Cache(a) = prune(in, in.limit)
  let atime = map.update(in.atime, key, touch_if_new)
  let items = map.insert(in.items, key, value)
  Lru(..in, items: items, atime: atime)
}

/// Get all cache keys.
pub fn keys(from: Cache(a)) -> List(String) {
  map.keys(from.items)
}

fn prune(in, limit) {
  case map.size(in.items) < limit {
    True -> in
    False -> {
      let fallback =
        in.items
        |> map.keys()
        |> list.first()
      let oldest_key =
        in.atime
        |> map.to_list()
        |> list.sort(fn(a, b) { int.compare(a.1, b.1) })
        |> list.first()
        |> result.map(fn(a) { a.0 })
        |> result.or(fallback)
      case oldest_key {
        // this can't happen, but the compiler doesn't know that
        Error(_) -> Lru(..in, items: map.new(), atime: map.new())
        Ok(oldest_key) -> {
          // this should leave less garbage than map.delete, even if it is slower
          let items = new_map_without(in.items, oldest_key)
          let atime = new_map_without(in.atime, oldest_key)
          Lru(..in, items: items, atime: atime)
        }
      }
    }
  }
}

fn new_map_without(m: Map(a, b), k: a) -> Map(a, b) {
  map.fold(
    m,
    map.new(),
    fn(acc, key, val) {
      case key == k {
        True -> acc
        False -> map.insert(acc, key, val)
      }
    },
  )
}

fn touch(in, key, ts) {
  Lru(..in, atime: map.insert(in.atime, key, ts()))
}
