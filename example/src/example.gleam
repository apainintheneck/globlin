import gleam/io
import gleam/list
import gleam/string
import path_pattern
import simplifile.{type FileError}

pub fn main() {
  case glob("**/*.gleam") {
    Ok(files) -> {
      files
      |> list.sort(string.compare)
      |> list.each(io.println)
    }
    Error(err) -> {
      io.print("File error: ")
      io.debug(err)
      Nil
    }
  }
}

fn glob(pattern: String) -> Result(List(String), FileError) {
  let assert Ok(directory) = simplifile.current_directory()
  let assert Ok(matcher) =
    path_pattern.new_pattern_with(
      pattern,
      from: directory,
      with: path_pattern.PatternOptions(False, False),
    )

  case simplifile.get_files(in: directory) {
    Ok(files) ->
      Ok(
        list.filter(files, path_pattern.match_pattern(pattern: matcher, path: _)),
      )
    Error(err) -> Error(err)
  }
}
