import gleam/list
import gleam/regex
import gleam/string

/// Each path pattern holds a compiled regex and options.
pub opaque type PathPattern {
  PathPattern(regex: regex.Regex, options: Options)
}

/// Options that can be provided to the `compile` method.
///
/// - ignore_case: All matching is case insensitive (Default: False)
/// - match_dotfiles: Match dotfiles when using wildcards (Default: False)
pub type Options {
  Options(ignore_case: Bool, match_dotfiles: Bool)
}

const empty_options = Options(ignore_case: False, match_dotfiles: False)

/// Errors:
/// - AbsolutePatternFromDirError
///   - The pattern must NOT start with a slash if compiled with a directory prefix.
/// - InvalidGlobStarError
///   - The globstar ("**") must always appear between the end of a string and/or a slash.
/// - MissingClosingBracketError
///   - A char set or range was opened but never closed.
/// - RegexCompileError
///   - Error propogated from the `gleam/regex` library.
///   - This should NEVER happen so let me know if you ever see this.
pub type Error {
  AbsolutePatternFromDirError
  InvalidGlobStarError
  MissingClosingBracketError
  RegexCompileError(context: regex.CompileError)
}

/// Compile a `PathPattern` from a pattern.
pub fn for_pattern(pattern pattern: String) -> Result(PathPattern, Error) {
  compile(directory: "", pattern:, with: empty_options)
}

/// Compile a `PathPattern` from a pattern and a directory prefix.
pub fn for_pattern_from_directory(
  pattern pattern: String,
  directory directory: String,
) -> Result(PathPattern, Error) {
  compile(directory:, pattern:, with: empty_options)
}

/// Compile a `PathPattern` from a directory, pattern and options. Leave the
/// directory blank if it's not needed and it will be ignored.
pub fn compile(
  directory directory: String,
  pattern pattern: String,
  with options: Options,
) -> Result(PathPattern, Error) {
  case convert_pattern(directory, pattern, options) {
    Ok(pattern) -> {
      let regex_options =
        regex.Options(case_insensitive: options.ignore_case, multi_line: False)
      case regex.compile(pattern, with: regex_options) {
        Ok(regex) -> Ok(PathPattern(regex:, options:))
        Error(err) -> Error(RegexCompileError(err))
      }
    }
    Error(err) -> Error(err)
  }
}

/// Compare a path pattern against a path to see if they match.
pub fn check(with pattern: PathPattern, path path: String) -> Bool {
  regex.check(with: pattern.regex, content: path)
}

// Convert path pattern graphemes into a regex syntax string.
fn convert_pattern(
  prefix: String,
  pattern: String,
  options: Options,
) -> Result(String, Error) {
  let graphemes = string.to_graphemes(pattern)
  let path_chars = parse_path_chars(prefix)

  case graphemes, path_chars {
    ["/", ..], [_, ..] -> Error(AbsolutePatternFromDirError)
    _, _ -> {
      case do_convert_pattern(graphemes, path_chars, False, options) {
        Ok(regex_pattern) -> Ok("^" <> regex_pattern <> "$")
        Error(err) -> Error(err)
      }
    }
  }
}

// Escape all characters in the directory prefix and add a slash
// before the following regex pattern if it's not already there.
//
// Note: The chars are returned in reverse order since we will
// be prepending to them later on in the `do_convert_pattern` method.
fn parse_path_chars(prefix: String) -> List(String) {
  prefix
  |> string.to_graphemes
  |> list.map(escape_meta_char)
  |> list.reverse
  |> fn(path_chars) {
    case path_chars {
      [] | ["/", ..] -> path_chars
      _ -> ["/", ..path_chars]
    }
  }
}

// Recursively convert path pattern graphemes into a regex syntax string.
fn do_convert_pattern(
  graphemes: List(String),
  path_chars: List(String),
  in_range: Bool,
  options: Options,
) -> Result(String, Error) {
  case in_range {
    True -> {
      case graphemes {
        // Error since we've reached the end with an open char set
        [] -> Error(MissingClosingBracketError)
        // Unescaped closing bracket means the char set is finished
        ["]", ..rest] ->
          do_convert_pattern(rest, ["]", ..path_chars], False, options)
        // Continue on until we find the closing bracket
        ["\\", second, ..rest] ->
          [escape_meta_char(second), ..path_chars]
          |> do_convert_pattern(rest, _, True, options)
        [first, ..rest] ->
          [escape_meta_char(first), ..path_chars]
          |> do_convert_pattern(rest, _, True, options)
      }
    }
    False -> {
      case graphemes {
        // Success
        [] -> path_chars |> list.reverse |> string.concat |> Ok
        // Match empty brackets literally
        ["[", "]", ..rest] ->
          do_convert_pattern(rest, ["\\[\\]", ..path_chars], False, options)
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
        // Convert "?" which matches any char once to regex format
        ["?", ..rest] -> {
          let wildcard = case ignore_dotfiles(path_chars, options) {
            True -> "[^/.]"
            False -> "[^/]"
          }
          do_convert_pattern(rest, [wildcard, ..path_chars], False, options)
        }
        // Convert "**" to regex format
        ["*", "*", ..rest] -> {
          case path_chars, rest {
            // Isolated "**" matches zero or more directories or files
            //
            // Example: "**"
            [], [] -> {
              let wildcard = case options.match_dotfiles {
                True -> ".*"
                False -> "([^.][^/]*(/[^.][^/]*)*)?"
              }
              let path_chars = [wildcard, ..path_chars]
              do_convert_pattern(rest, path_chars, False, options)
            }
            // Postfix "**" matches zero or more directories or files
            //
            // Example: "filler/**"
            ["/", ..path_chars], [] -> {
              let wildcard = case options.match_dotfiles {
                True -> "(/.*)?"
                False -> "(/[^.][^/]*)*"
              }
              let path_chars = [wildcard, ..path_chars]
              do_convert_pattern(rest, path_chars, False, options)
            }
            // Prefix or infix "**" matches zero or more directories
            //
            // Examples: "**/filler" or "filler/**/filler"
            [], ["/", ..rest] | ["/", ..], ["/", ..rest] -> {
              let wildcard = case options.match_dotfiles {
                True -> "(.*/)?"
                False -> "([^.][^/]*/)*"
              }
              let path_chars = [wildcard, ..path_chars]
              do_convert_pattern(rest, path_chars, False, options)
            }
            _, _ -> Error(InvalidGlobStarError)
          }
        }
        // Convert "*" which matches any char zero or more times except "/" to regex format
        ["*", ..rest] -> {
          let wildcard = case ignore_dotfiles(path_chars, options) {
            True -> "([^.][^/]*)?"
            False -> "[^/]*"
          }
          do_convert_pattern(rest, [wildcard, ..path_chars], False, options)
        }
        // Escape any other path chars if necessary
        [first, ..rest] ->
          [escape_meta_char(first), ..path_chars]
          |> do_convert_pattern(rest, _, False, options)
      }
    }
  }
}

// Escape regex meta characters that should be matched literally inside the regex.
fn escape_meta_char(char: String) -> String {
  case char {
    // Erlang: Metacharacters need to be escaped to avoid unexpected matching.
    // See https://www.erlang.org/doc/apps/stdlib/re.html#module-characters-and-metacharacters
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
    // JS: In unicode aware mode these need to be escaped explicitly.
    // See https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Errors/Regex_raw_bracket
    "]" -> "\\]"
    "}" -> "\\}"
    _ -> char
  }
}

// All wildcards ignore dotfiles by default unless the `match_dotfiles`
// option is present. It is also possible to match dotfiles using literal dots,
// char sets or ranges.
fn ignore_dotfiles(path_chars: List(String), options: Options) -> Bool {
  !options.match_dotfiles && start_of_directory(path_chars)
}

// The start of a directory is the beginning of the path pattern or
// anything immediately following a slash.
fn start_of_directory(path_chars: List(String)) -> Bool {
  case path_chars {
    [] | [""] -> True
    [previous, ..] -> string.ends_with(previous, "/")
  }
}
