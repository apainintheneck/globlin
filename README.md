# path_pattern

[![Package Version](https://img.shields.io/hexpm/v/path_pattern)](https://hex.pm/packages/path_pattern)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/path_pattern/)

```sh
gleam add path_pattern@1
```
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
