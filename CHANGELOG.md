# CHANGELOG

## v2.0.3
- Support separate `gleam_regexp` package since the original regex module got removed from the `gleam_stdlib` package

## v2.0.2
- Add note clarifying that this only supports Unix file paths right now

## v2.0.1
- Add references to the `globlin_fs` file system package
    - Includes the file system logic removed in v2.0.0

## v2.0.0 - 2024-08-19
- Remove file system dependencies so library can work in the browser
    - Remove `glob` and `glob_from` methods
    - Remove `simplifile` dependency
- Panic on regex compile error
    - Remove `RegexCompileError`
    - It should never happen anyway as we convert the pattern to valid regex syntax

## v1.0.1 - 2024-08-18
- Add in missing `simplifile` dependency
- Add in missing glob methods

## v1.0.0 - 2024-08-18
- First release!