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
  case convert_pattern(prefix, pattern, options) {
    Ok(pattern) -> {
      let regex_options =
        regex.Options(case_insensitive: options.ignore_case, multi_line: False)
      case regex.compile(pattern, with: regex_options) {
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

fn convert_pattern(
  prefix: String,
  pattern: String,
  options: Options,
) -> Result(String, Nil) {
  let graphemes = string.to_graphemes(pattern)
  let path_chars = [regex_escape(prefix)]
  case do_convert_pattern(graphemes, path_chars, False, options) {
    Ok(regex_pattern) -> Ok("^" <> regex_pattern <> "$")
    Error(_) -> Error(Nil)
  }
}

fn do_convert_pattern(
  graphemes: List(String),
  path_chars: List(String),
  in_range: Bool,
  options: Options,
) -> Result(String, Nil) {
  case in_range {
    True -> {
      case graphemes {
        // Error since we've reached the end with an open char set
        [] -> Error(Nil)
        // Unescaped closing bracket means the char set is finished
        ["]", ..rest] ->
          do_convert_pattern(rest, ["]", ..path_chars], False, options)
        // Continue on until we find the closing bracket
        ["\\", second, ..rest] ->
          [escape_meta_char(second), ..path_chars]
          |> do_convert_pattern(rest, _, True, options)
        [first, ..rest] ->
          do_convert_pattern(rest, [first, ..path_chars], True, options)
      }
    }
    False -> {
      case graphemes {
        // Success
        [] -> path_chars |> list.reverse |> string.concat |> Ok
        // Convert "?" which matches any char once to regex format
        ["?", ..rest] -> {
          let wildcard = case ignore_dotfiles(path_chars, options) {
            True -> "[^/.]"
            False -> "[^/]"
          }
          do_convert_pattern(rest, [wildcard, ..path_chars], False, options)
        }
        // Convert "**" which matches any char zero or more times including "/" to regex format
        ["*", "*", ..rest] -> {
          let wildcard = case ignore_dotfiles(path_chars, options) {
            // Match on everything
            _ if options.match_dotfiles -> ".*"
            // Start of directory: ignore all dotfiles
            True -> "(([^.][^/]*)(/[^.][^/]*)*)?"
            // Middle/end of directory: ignore all dotfiles but match on initial dot
            False -> "([^/]*(/[^.][^/]*)*)?"
          }
          do_convert_pattern(rest, [wildcard, ..path_chars], False, options)
        }
        // Convert "*" which matches any char zero or more times except "/" to regex format
        ["*", ..rest] -> {
          let wildcard = case ignore_dotfiles(path_chars, options) {
            True -> "([^.][^/]*)?"
            False -> "[^/]*"
          }
          do_convert_pattern(rest, [wildcard, ..path_chars], False, options)
        }
        // Match empty brackets literally
        ["[", "]", ..rest] ->
          do_convert_pattern(rest, ["\\[]", ..path_chars], False, options)
        // Convert "[!" negative char set to regex format
        ["[", "!", ..rest] ->
          do_convert_pattern(rest, ["[^", ..path_chars], True, options)
        // Convert "[^" positive char set to regex format ("^" has no special meaning here)
        ["[", "^", ..rest] ->
          do_convert_pattern(rest, ["[\\^", ..path_chars], True, options)
        // Convert "[" positive char set to regex format
        ["[", ..rest] ->
          do_convert_pattern(rest, ["[", ..path_chars], True, options)
        // Escape any path chars preceded by a "\" only if necessary
        ["\\", second, ..rest] ->
          [escape_meta_char(second), ..path_chars]
          |> do_convert_pattern(rest, _, False, options)
        // Escape any other path chars if necessary
        [first, ..rest] ->
          [escape_meta_char(first), ..path_chars]
          |> do_convert_pattern(rest, _, False, options)
      }
    }
  }
}

// Both wildcards ignore dotfiles by default unless the `match_dotfiles`
// option is present. It is also possible to match dotfiles using literal dots
// char sets or ranges.
fn ignore_dotfiles(path_chars: List(String), options: Options) -> Bool {
  !options.match_dotfiles && start_of_directory(path_chars)
}

fn start_of_directory(path_chars: List(String)) -> Bool {
  case path_chars {
    [] | [""] -> True
    [previous, ..] -> string.ends_with(previous, "/")
  }
}
