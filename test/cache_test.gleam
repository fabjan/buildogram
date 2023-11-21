import gleam/erlang/atom.{type Atom}
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

/// Create a fake timer which returns a higher value each time it is called.
/// Leverages the mutability in the `counters` Erlang stdlib module.
fn fake_timer() {
  let counter = counters_new(1, [])
  fn() {
    // N.B. 1-based index
    counters_add(counter, 1, 1)
    counters_get(counter, 1)
  }
}

/// fake timer FFI helpers
type Counter

@external(erlang, "counters", "new")
fn counters_new(size size: Int, opts opts: List(Atom)) -> Counter

/// Read counter value.
@external(erlang, "counters", "get")
fn counters_get(ref ref: Counter, ix ix: Int) -> Int

/// Add incr to counter at index ix.
@external(erlang, "counters", "add")
fn counters_add(ref ref: Counter, ix ix: Int, incr incr: Int) -> Int
