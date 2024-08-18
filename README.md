# path_pattern

[![Package Version](https://img.shields.io/hexpm/v/path_pattern)](https://hex.pm/packages/path_pattern)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/path_pattern/)

This package brings `fnmatch` path matching to Gleam. A `PathPattern` is created by compiling the glob pattern string into the equivalent regex internally. This pattern can then be compared against other strings to find matching paths.

## Add Dependency

```sh
gleam add path_pattern
```

## Pattern Syntax

There are seven special matching patterns supported by this package. They should be familiar to anyone who has used similar packages before.

### Question Mark `?`

This matches any single character except the slash `/`.

### Star `*`

This matches zero or more characters except the slash `/`.

### Globstar `**`

This matches zero or more directories. It must be surrounded by the end of the string or slash `/`.

Examples:
- Isolated: `**`
- Prefix: `**/tail`
- Infix: `head/**/tail`
- Postfix: `**`

Note: When found at the end of the pattern, it matches all directories and files.

### Inclusive Char Set `[abc]`

This matches any character in the set.

### Exclusive Char Set `[!abc]`

This matches any character not in the set when the exclamation point `!` follows the opening square bracket.

### Inclusive Range `[a-z]`

This matches any character from start to finish.

### Exclusive Range `[!a-z]`

This matches any character not included in a range.

## Option Flags

There are two option flags available to change the behavior of matching. They are both turned off by default when using the `for_pattern` and `for_pattern_from_directory` methods.

### `ignore_case`

This changes all matches to be case insensitive.

### `match_dotfiles`

Allow wildcards like `?`, `*` and `**` to match dotfiles.

## Example

```gleam
import gleam/io
import gleam/list
import path_pattern

pub fn main() {
  let assert Ok(matcher) = path_pattern.for_pattern("**/*.gleam")

  [
    "src/main.gleam", "src/path_pattern.gleam", "test/path_pattern_test.gleam",
    ".gitignore", "gleam/toml", "LICENSE", "manifest.toml", "README.md",
  ]
  |> list.filter(path_pattern.check(with: matcher, path: _))
  |> list.each(io.debug)
}
```

Further documentation can be found at <https://hexdocs.pm/path_pattern>.

## Development

```sh
gleam test  # Run the tests
```
