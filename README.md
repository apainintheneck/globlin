# globlin

[![Package Version](https://img.shields.io/hexpm/v/globlin)](https://hex.pm/packages/globlin)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/globlin/)

This package brings file globbing to Gleam. A `Pattern` is created by compiling the glob pattern string into the equivalent regex internally. This pattern can then be compared against other strings to find matching paths.

Note: This library doesn't include methods to directly query the file system so that it can be used in the browser where that isn't available. If you're looking for file system globbing, check out the [globlin_fs](https://hexdocs.pm/globlin_fs/index.html) package.

Note 2: This library only currently supports Unix file paths. That means it should work on Linux, macOS and BSD.

## Add Dependency

```sh
gleam add globlin
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

There are two option flags available to change the behavior of matching. They are both turned off by default when using the `new_pattern` method.

### `ignore_case`

This changes all matches to be case insensitive.

### `match_dotfiles`

Allow wildcards like `?`, `*` and `**` to match dotfiles.

## Example

```gleam
import gleam/io
import gleam/list
import globlin

pub fn main() {
  let files = [
    ".gitignore", "gleam.toml", "LICENCE", "manifest.toml", "README.md",
    "src/globlin.gleam", "test/globlin_test.gleam",
  ]

  let assert Ok(pattern) = globlin.new_pattern("**/*.gleam")

  files
  |> list.filter(keeping: globlin.match_pattern(pattern:, path: _))
  |> list.each(io.println)
  // src/globlin.gleam
  // test/globlin_test.gleam
}
```

Further documentation can be found at <https://hexdocs.pm/globlin>.

## Development

```sh
gleam test  # Run the tests
```
