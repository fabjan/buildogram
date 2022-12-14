import gleam/erlang/atom.{Atom}
import gleeunit/should
import buildogram/cache

pub fn get_empty_test() {
  let c = cache.lru(1, fake_timer())

  cache.get(c, "key")
  |> should.equal(#(c, Error(Nil)))
}

pub fn set_get_test() {
  let c = cache.lru(1, fake_timer())
  let c = cache.set(c, "key", "value")

  let v = cache.get(c, "key").1

  v
  |> should.equal(Ok("value"))
}

pub fn evict_insert_test() {
  let c = cache.lru(2, fake_timer())
  let c = cache.set(c, "key1", "value1")
  let c = cache.set(c, "key2", "value2")

  // should have all keys
  cache.keys(c)
  |> should.equal(["key1", "key2"])

  let c = cache.set(c, "key3", "value3")

  // should have only the last two keys (limit is 2)
  cache.keys(c)
  |> should.equal(["key2", "key3"])
}

pub fn evict_touch_test() {
  let c = cache.lru(2, fake_timer())
  let c = cache.set(c, "key1", "value1")
  let c = cache.set(c, "key2", "value2")

  // get key1 to touch it
  let c = cache.get(c, "key1").0

  let c = cache.set(c, "key3", "value3")

  // should have only the last two keys (limit is 2)
  // key1 is more recent than key2, so it should be kept
  cache.keys(c)
  |> should.equal(["key1", "key3"])

  cache.get(c, "key1").1
  |> should.equal(Ok("value1"))

  cache.get(c, "key2").1
  |> should.equal(Error(Nil))

  cache.get(c, "key3").1
  |> should.equal(Ok("value3"))
}

/// fake timer helper
external type Counter

/// Create a new counter array of `size` counters. All counters in the array are initially set to zero.
/// Indexes into counter arrays are one-based.
/// Valid options are:
///   * `atomics` - Use atomics for the counters. This is the default.
///   * `write_concurrency` - Better write concurrency but worse read consistency.
external fn counters_new(size: Int, opts: List(Atom)) -> Counter =
  "counters" "new"

/// Read counter value.
external fn counters_get(ref: Counter, ix: Int) -> Int =
  "counters" "get"

/// Add incr to counter at index ix.
external fn counters_add(ref: Counter, ix: Int, incr: Int) -> Int =
  "counters" "add"

fn fake_timer() {
  let counter = counters_new(1, [])
  fn() {
    // N.B. 1-based index
    counters_add(counter, 1, 1)
    counters_get(counter, 1)
  }
}
