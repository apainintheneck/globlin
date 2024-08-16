/// Some of these tests are based on the tests in the Python standard library for the `fnmatch` library.
/// 
/// Source: https://github.com/python/cpython/blob/e913d2c87f1ae4e7a4aef5ba78368ef31d060767/Lib/test/test_fnmatch.py
/// 
import gleam/list
import gleam/string
import gleeunit
import gleeunit/should
import path_pattern

pub fn main() {
  gleeunit.main()
}

type Pair {
  Pair(content: String, pattern: String)
}

fn check_pattern(
  pair pair: Pair,
  is_match is_match: Bool,
  ignore_case ignore_case: Bool,
) -> Nil {
  path_pattern.from_pattern(pattern: pair.pattern, ignore_case: ignore_case)
  |> should.be_ok
  |> path_pattern.check(pair.content)
  |> should.equal(is_match)
}

pub fn simple_patterns_test() {
  [
    Pair(content: "abc", pattern: "abc"),
    Pair(content: "abc", pattern: "?*?"),
    Pair(content: "abc", pattern: "???*"),
    Pair(content: "abc", pattern: "*???"),
    Pair(content: "abc", pattern: "???"),
    Pair(content: "abc", pattern: "*"),
    Pair(content: "abc", pattern: "ab[cd]"),
    Pair(content: "abc", pattern: "ab[!de]"),
  ]
  |> list.each(check_pattern(pair: _, is_match: True, ignore_case: False))

  [
    Pair(content: "abc", pattern: "ab[de]"),
    Pair(content: "a", pattern: "??"),
    Pair(content: "a", pattern: "b"),
  ]
  |> list.each(check_pattern(pair: _, is_match: False, ignore_case: False))
}

pub fn paths_with_newlines_test() {
  [
    Pair("foo\nbar", "foo*"),
    Pair("foo\nbar\n", "foo*"),
    Pair("\nfoo", "foo*"),
    Pair("\n", "*"),
  ]
  |> list.each(check_pattern(pair: _, is_match: True, ignore_case: False))
}

pub fn slow_patterns_test() {
  [
    Pair(content: string.repeat("a", 50), pattern: "*a*a*a*a*a*a*a*a*a*a"),
    Pair(
      content: string.repeat("a", 50) <> "b",
      pattern: "*a*a*a*a*a*a*a*a*a*a",
    ),
  ]
  |> list.each(check_pattern(pair: _, is_match: True, ignore_case: False))
}

pub fn case_sensitivity_test() {
  [Pair("abc", "abc"), Pair("AbC", "AbC")]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: True, ignore_case: False)
    check_pattern(pair: pair, is_match: True, ignore_case: True)
  })

  [Pair("AbC", "abc"), Pair("abc", "AbC")]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: False, ignore_case: False)
    check_pattern(pair: pair, is_match: True, ignore_case: True)
  })
}
