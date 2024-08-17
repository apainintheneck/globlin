import gleam/list
import gleam/regex
import gleam/string

pub opaque type PathPattern {
  PathPattern(regex: regex.Regex, options: Options)
}

pub type Options {
  Options(ignore_case: Bool, match_dotfiles: Bool)
}

const empty_options = Options(ignore_case: False, match_dotfiles: False)

pub type Error {
  MissingClosingBracketError
  RegexCompileError(context: regex.CompileError)
}

pub fn from_pattern(pattern pattern: String) -> Result(PathPattern, Error) {
  compile(prefix: "", pattern:, with: empty_options)
}

pub fn from_prefix_and_pattern(
  prefix prefix: String,
  pattern pattern: String,
) -> Result(PathPattern, Error) {
  compile(prefix:, pattern:, with: empty_options)
}

pub fn compile(
  prefix prefix: String,
  pattern pattern: String,
  with options: Options,
) -> Result(PathPattern, Error) {
  let prefix = regex_escape(prefix)
  case convert_pattern(pattern) {
    Ok(pattern) -> {
      let regex_options =
        regex.Options(case_insensitive: options.ignore_case, multi_line: False)
      case regex.compile(prefix <> pattern, with: regex_options) {
        Ok(regex) -> Ok(PathPattern(regex:, options:))
        Error(err) -> Error(RegexCompileError(err))
      }
    }
    Error(_) -> Error(MissingClosingBracketError)
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
        // Error since we've reached the end with an open char set
        [] -> Error(Nil)
        // Unescaped closing bracket means the char set is finished
        ["]", ..rest] -> do_convert_pattern(rest, ["]", ..chars], False)
        // Continue on until we find the closing bracket
        ["\\", second, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(second), ..chars], True)
        [first, ..rest] -> do_convert_pattern(rest, [first, ..chars], True)
      }
    }
    False -> {
      case graphemes {
        // Success
        [] -> chars |> list.reverse |> string.concat |> Ok
        // Convert "?" which matches any char once to regex format
        ["?", ..rest] -> do_convert_pattern(rest, ["[^/]", ..chars], False)
        // Convert "**" which matches any char zero or more times including "/" to regex format
        ["*", "*", ..rest] -> do_convert_pattern(rest, [".*", ..chars], False)
        // Convert "*" which matches any char zero or more times except "/" to regex format
        ["*", ..rest] -> do_convert_pattern(rest, ["[^/]*", ..chars], False)
        // Match empty brackets literally
        ["[", "]", ..rest] -> do_convert_pattern(rest, ["\\[]", ..chars], False)
        // Convert "[!" negative char set to regex format
        ["[", "!", ..rest] -> do_convert_pattern(rest, ["[^", ..chars], True)
        // Convert "[^" positive char set to regex format ("^" has no special meaning here)
        ["[", "^", ..rest] -> do_convert_pattern(rest, ["[\\^", ..chars], True)
        // Convert "[" positive char set to regex format
        ["[", ..rest] -> do_convert_pattern(rest, ["[", ..chars], True)
        // Escape any chars preceded by a "\" only if necessary
        ["\\", second, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(second), ..chars], False)
        // Escape any other chars if necessary
        [first, ..rest] ->
          do_convert_pattern(rest, [escape_meta_char(first), ..chars], False)
      }
    }
  }
}
