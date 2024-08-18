import gleam/io
import gleam/list
import gleam/string
import path_pattern
import simplifile

pub fn main() {
  let pattern = "**/*.gleam"
  let assert Ok(directory) = simplifile.current_directory()
  let assert Ok(matcher) =
    path_pattern.for_pattern_from_directory(pattern:, directory:)

  case simplifile.get_files(in: directory) {
    Ok(files) -> {
      files
      |> list.filter(path_pattern.check(with: matcher, path: _))
      |> list.sort(string.compare)
      |> list.each(io.println)
    }
    Error(err) -> {
      io.print("File reading error: ")
      io.debug(err)
      Nil
    }
  }
}
