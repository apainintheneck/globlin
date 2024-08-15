import gleam/list
import gleam/regex
import gleam/string

pub opaque type PathPattern {
  PathPattern(regex: regex.Regex)
}

pub fn from_pattern(
  pattern pattern: String,
  ignore_case ignore_case: Bool,
) -> Result(PathPattern, Nil) {
  from_prefix_and_string("", pattern, ignore_case)
}

pub fn from_prefix_and_string(
  prefix prefix: String,
  pattern pattern: String,
  ignore_case ignore_case: Bool,
) -> Result(PathPattern, Nil) {
  let prefix = regex_escape(prefix)
  case convert_pattern(pattern) {
    Ok(pattern) -> {
      let options =
        regex.Options(case_insensitive: ignore_case, multi_line: False)
      case regex.compile(prefix <> pattern, with: options) {
        Ok(regex) -> Ok(PathPattern(regex:))
        Error(_) -> Error(Nil)
      }
    }
    Error(_) -> Error(Nil)
  }
}

pub fn check(with pattern: PathPattern, path path: String) -> Bool {
  regex.check(with: pattern.regex, content: path)
}

fn regex_escape(content: String) -> String {
  content
  |> string.to_graphemes
  |> list.map(escape_meta_char)
  |> string.concat
}

// See https://www.erlang.org/doc/apps/stdlib/re.html#module-characters-and-metacharacters
fn escape_meta_char(char: String) -> String {
  case char {
    "\\" -> "\\\\"
    "^" -> "\\^"
    "$" -> "\\$"
    "." -> "\\."
    "[" -> "\\["
    "|" -> "\\|"
    "(" -> "\\("
    ")" -> "\\)"
    "?" -> "\\?"
    "*" -> "\\*"
    "+" -> "\\+"
    "{" -> "\\{"
    _ -> char
  }
}

fn convert_pattern(pattern: String) -> Result(String, Nil) {
  let graphemes = string.to_graphemes(pattern)
  do_convert_pattern(graphemes, [], False)
}

fn do_convert_pattern(
  graphemes: List(String),
  chars: List(String),
  in_range: Bool,
) -> Result(String, Nil) {
  case in_range {
    True -> {
      case graphemes {
        [] -> Error(Nil)
        ["]", ..rest] -> do_convert_pattern(rest, ["]", ..chars], False)
        ["\\", second, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(second), ..chars], True)
        [first, ..rest] -> do_convert_pattern(rest, [first, ..chars], True)
      }
    }
    False -> {
      case graphemes {
        [] -> chars |> list.reverse |> string.concat |> Ok
        ["?", ..rest] -> do_convert_pattern(rest, ["[^/]", ..chars], False)
        ["*", "*", ..rest] -> do_convert_pattern(rest, [".*", ..chars], False)
        ["*", ..rest] -> do_convert_pattern(rest, ["[^/]*", ..chars], False)
        ["[", "]", ..rest] -> do_convert_pattern(rest, ["\\[]", ..chars], False)
        ["[", "!", ..rest] -> do_convert_pattern(rest, ["[^", ..chars], True)
        ["[", ..rest] -> do_convert_pattern(rest, ["[", ..chars], True)
        ["\\", second, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(second), ..chars], False)
        [first, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(first), ..chars], False)
      }
    }
  }
}
