// History and completion management for readline

// History management

///|
pub struct History {
  mut entries : Array[String]
  mut max_size : Int
  mut remove_duplicates : Bool
  mut current_index : Int
}

///|
fn History::new(
  max_size~ : Int = 1000,
  remove_duplicates~ : Bool = true,
) -> History {
  History::{
    entries: Array::new(),
    max_size,
    remove_duplicates,
    current_index: -1,
  }
}

///|
fn History::add(self : History, entry : String) -> Unit {
  if entry.length() == 0 {
    return
  }

  // Remove duplicates if enabled
  if self.remove_duplicates {
    self.entries.retain(fn(e) { e != entry })
  }

  // Add new entry
  self.entries.push(entry)

  // Maintain max size
  while self.entries.length() > self.max_size {
    self.entries.remove(0) |> ignore |> ignore |> ignore
  }

  // Reset current index
  self.current_index = self.entries.length()
}

///|
fn History::get(self : History, index : Int) -> String? {
  if index >= 0 && index < self.entries.length() {
    Some(self.entries[index])
  } else {
    None
  }
}

///|
fn History::length(self : History) -> Int {
  self.entries.length()
}

///|
fn History::clear(self : History) -> Unit {
  self.entries.clear()
  self.current_index = -1
}

///|
fn History::get_all(self : History) -> Array[String] {
  self.entries.copy()
}

///|
fn History::set_max_size(self : History, size : Int) -> Unit {
  self.max_size = size
  while self.entries.length() > self.max_size {
    self.entries.remove(0)
  }
}

// Navigation methods for readline

///|
fn History::previous(self : History) -> String? {
  if self.entries.length() == 0 {
    return None
  }
  if self.current_index > 0 {
    self.current_index = self.current_index - 1
  }
  self.get(self.current_index)
}

///|
fn History::next(self : History) -> String? {
  if self.entries.length() == 0 {
    return None
  }
  if self.current_index < self.entries.length() - 1 {
    self.current_index = self.current_index + 1
    self.get(self.current_index)
  } else {
    self.current_index = self.entries.length()
    Some("") // Return empty string when going past the end
  }
}

// Search functionality

///|
fn History::search(self : History, pattern : String) -> Array[String] {
  let results = Array::new()
  for entry in self.entries {
    if entry.contains(pattern) {
      results.push(entry)
    }
  }
  results
}

///|
fn History::reverse_search(self : History, pattern : String) -> String? {
  // Search backwards from current position
  for i = self.current_index - 1; i >= 0; i = i - 1 {
    let entry = self.entries[i]
    if entry.contains(pattern) {
      self.current_index = i
      return Some(entry)
    }
  }
  None
}

// Completion system
// Note: CompletionFunction type is defined in readline.mbt

///|
pub struct Completer {
  mut completion_fn : CompletionFunction?
  mut word_break_chars : String
}

///|
fn Completer::new(completion_fn~ : CompletionFunction? = None) -> Completer {
  Completer::{ completion_fn, word_break_chars: " \t\n\"\\'`@$><=;|&{(" }
}

///|
fn Completer::complete(
  self : Completer,
  line : String,
  cursor_pos : Int,
) -> (Array[String], String) {
  match self.completion_fn {
    Some(fn_ref) => {
      // Extract the word being completed
      let word_start = self.find_word_start(line, cursor_pos)
      let word = line.substring(word_start, cursor_pos)
      fn_ref(word)
    }
    None => (Array::new(), "")
  }
}

///|
fn Completer::find_word_start(
  self : Completer,
  line : String,
  cursor_pos : Int,
) -> Int {
  let mut start = cursor_pos - 1
  while start >= 0 {
    let char = line.get(start).unwrap_or(' ')
    if self.word_break_chars.contains(char.to_string()) {
      return start + 1
    }
    start = start - 1
  }
  0
}

///|
fn Completer::set_completion_function(
  self : Completer,
  fn_ref : CompletionFunction,
) -> Unit {
  self.completion_fn = Some(fn_ref)
}

///|
fn Completer::set_word_break_chars(self : Completer, chars : String) -> Unit {
  self.word_break_chars = chars
}

// Built-in completion functions

///|
pub fn file_path_completer(word : String) -> (Array[String], String) {
  // Simple file path completion
  // In a full implementation, this would scan the file system
  let completions = Array::new()

  // Mock implementation - in practice, we'd scan directories
  if word.starts_with("/") {
    completions.push("/usr/")
    completions.push("/home/")
    completions.push("/etc/")
  } else if word.starts_with("./") {
    completions.push("./src/")
    completions.push("./lib/")
    completions.push("./bin/")
  } else {
    completions.push("src/")
    completions.push("lib/")
    completions.push("README.md")
  }

  // Filter completions that start with the word
  let filtered = Array::new()
  for completion in completions {
    if completion.starts_with(word) {
      filtered.push(completion)
    }
  }
  (filtered, word)
}

///|
pub fn command_completer(commands : Array[String]) -> CompletionFunction {
  fn(word : String) -> (Array[String], String) {
    let filtered = Array::new()
    for command in commands {
      if command.starts_with(word) {
        filtered.push(command)
      }
    }
    (filtered, word)
  }
}

///|
pub fn create_list_completer(options : Array[String]) -> CompletionFunction {
  fn(word : String) -> (Array[String], String) {
    let filtered = Array::new()
    for option in options {
      if option.starts_with(word) {
        filtered.push(option)
      }
    }
    (filtered, word)
  }
}

// Fuzzy completion

///|
pub fn fuzzy_completer(options : Array[String]) -> CompletionFunction {
  fn(word : String) -> (Array[String], String) {
    let filtered = Array::new()
    for option in options {
      if fuzzy_match(word, option) {
        filtered.push(option)
      }
    }
    // Sort by relevance (simple implementation)
    filtered.sort_by(fn(a, b) {
      let score_a = fuzzy_score(word, a)
      let score_b = fuzzy_score(word, b)
      score_b.compare(score_a) // Higher scores first
    })
    (filtered, word)
  }
}

///|
fn fuzzy_match(pattern : String, text : String) -> Bool {
  let mut pattern_idx = 0
  let mut text_idx = 0
  while pattern_idx < pattern.length() && text_idx < text.length() {
    if pattern.get(pattern_idx) == text.get(text_idx) {
      pattern_idx = pattern_idx + 1
    }
    text_idx = text_idx + 1
  }
  pattern_idx == pattern.length()
}

///|
fn fuzzy_score(pattern : String, text : String) -> Int {
  let mut score = 0
  let mut pattern_idx = 0
  let mut last_match = -1
  for text_idx = 0; text_idx < text.length(); text_idx = text_idx + 1 {
    if pattern_idx < pattern.length() &&
      pattern.get(pattern_idx) == text.get(text_idx) {
      score = score + 1
      // Consecutive matches get bonus points
      if last_match == text_idx - 1 {
        score = score + 1
      }
      last_match = text_idx
      pattern_idx = pattern_idx + 1
    }
  }

  // Exact prefix match gets high score
  if text.starts_with(pattern) {
    score = score + 10
  }
  score
}

// History-based completion

///|
pub fn history_completer(history : History) -> CompletionFunction {
  fn(word : String) -> (Array[String], String) {
    let completions = Array::new()
    let seen = Map::new()

    // Search through history entries
    for entry in history.get_all() {
      if entry.starts_with(word) && not(seen.contains(entry)) {
        completions.push(entry)
        seen.set(entry, true)
      }
    }

    // Sort by most recent first (reverse order since we added chronologically)
    completions.reverse()
    (completions, word)
  }
}

// Multi-source completer

///|
pub fn create_multi_completer(
  completers : Array[CompletionFunction],
) -> CompletionFunction {
  fn(word : String) -> (Array[String], String) {
    let all_completions = Array::new()
    let seen = Map::new()
    for completer in completers {
      let (completions, _) = completer(word)
      for completion in completions {
        if not(seen.contains(completion)) {
          all_completions.push(completion)
          seen.set(completion, true)
        }
      }
    }
    (all_completions, word)
  }
}

// Tab completion display utilities

///|
pub fn format_completions(
  completions : Array[String],
  columns~ : Int = 80,
) -> String {
  if completions.length() == 0 {
    return ""
  }
  if completions.length() == 1 {
    return completions[0]
  }

  // Calculate column width
  let max_width = completions.fold(0, fn(acc, item) {
    let len = item.length()
    if len > acc {
      len
    } else {
      acc
    }
  })
  let col_width = max_width + 2
  let cols_per_line = columns / col_width
  let mut result = "\n"
  for i, completion in completions {
    result = result + completion.pad_right(col_width)
    if (i + 1) % cols_per_line == 0 {
      result = result + "\n"
    }
  }
  if completions.length() % cols_per_line != 0 {
    result = result + "\n"
  }
  result
}

// String padding utility

///|
fn String::pad_right(self : String, width : Int) -> String {
  if self.length() >= width {
    self
  } else {
    let padding = " ".repeat(width - self.length())
    self + padding
  }
}
