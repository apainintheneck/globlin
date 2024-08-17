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

const empty_options = path_pattern.Options(
  ignore_case: False,
  match_dotfiles: False,
)

const no_case_options = path_pattern.Options(
  ignore_case: True,
  match_dotfiles: False,
)

const with_dots_options = path_pattern.Options(
  ignore_case: False,
  match_dotfiles: True,
)

fn check_pattern(
  pair pair: Pair,
  is_match is_match: Bool,
  options options: path_pattern.Options,
) -> Nil {
  path_pattern.compile(prefix: "", pattern: pair.pattern, with: options)
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
  |> list.each(check_pattern(pair: _, is_match: True, options: empty_options))

  [
    Pair(content: "abc", pattern: "ab[de]"),
    Pair(content: "a", pattern: "??"),
    Pair(content: "a", pattern: "b"),
  ]
  |> list.each(check_pattern(pair: _, is_match: False, options: empty_options))
}

pub fn paths_with_newlines_test() {
  [
    Pair(content: "foo\nbar", pattern: "foo*"),
    Pair(content: "foo\nbar\n", pattern: "foo*"),
    Pair(content: "\nfoo", pattern: "\nfoo*"),
    Pair(content: "\n", pattern: "*"),
  ]
  |> list.each(check_pattern(pair: _, is_match: True, options: empty_options))
}

pub fn slow_patterns_test() {
  [
    Pair(content: string.repeat("a", 50), pattern: "*a*a*a*a*a*a*a*a*a*a"),
    Pair(
      content: string.repeat("a", 50) <> "b",
      pattern: "*a*a*a*a*a*a*a*a*a*ab",
    ),
  ]
  |> list.each(check_pattern(pair: _, is_match: True, options: empty_options))
}

pub fn case_sensitivity_test() {
  [Pair(content: "abc", pattern: "abc"), Pair(content: "AbC", pattern: "AbC")]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: True, options: empty_options)
    check_pattern(pair: pair, is_match: True, options: no_case_options)
  })

  [Pair(content: "AbC", pattern: "abc"), Pair(content: "abc", pattern: "AbC")]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: False, options: empty_options)
    check_pattern(pair: pair, is_match: True, options: no_case_options)
  })
}

pub fn dotfiles_test() {
  [
    Pair(content: ".secrets.txt", pattern: "*"),
    Pair(content: "repo/.git", pattern: "**it"),
    Pair(content: ".vimrc", pattern: "?vim*"),
  ]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: False, options: empty_options)
    check_pattern(pair: pair, is_match: True, options: with_dots_options)
  })

  [
    Pair(content: "go/pkg/.mod/golang.org/", pattern: "go/*/.mod/*/"),
    Pair(content: ".vscode/argv.json", pattern: ".vsco**"),
    Pair(content: "/path/README.md", pattern: "/path/README???"),
  ]
  |> list.each(fn(pair) {
    check_pattern(pair: pair, is_match: True, options: empty_options)
    check_pattern(pair: pair, is_match: True, options: with_dots_options)
  })
}

pub fn invalid_pattern_test() {
  ["[", "abc[def", "abc[def\\]g", "]]]][[]["]
  |> list.each(fn(pattern) {
    path_pattern.from_pattern(pattern)
    |> should.equal(Error(path_pattern.MissingClosingBracketError))
  })
}
