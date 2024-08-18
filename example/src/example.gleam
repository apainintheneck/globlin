import gleam/io
import gleam/list
import gleam/string
import globlin

pub fn main() {
  let assert Ok(pattern) = globlin.new_pattern("**/*.gleam")
  case globlin.glob(pattern) {
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
