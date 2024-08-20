# CHANGELOG

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