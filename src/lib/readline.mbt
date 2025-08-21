// Main readline module - Node.js compatible interface

// Re-export all public types and functions for a clean API
// Note: We import the types and functions we need directly

// Import CompletionFunction type from history module

///|
typealias (String) -> (Array[String], String) as CompletionFunction

// Import completion functions from history.mbt
// file_path_completer is now defined in history.mbt

// command_completer is now defined in history.mbt

// Main readline module functions (Node.js compatible)

///| Create a readline interface with specified options

///| Create a simple readline interface with just input/output streams  
pub fn createInterface(input? : String, output? : String) -> Interface {
  create_interface_simple(input~, output~)
}

///| Create a readline interface with full options
pub fn createInterfaceWithOptions(options : InterfaceOptions) -> Interface {
  create_interface(options)
}

// Note: Async interfaces would be available when MoonBit has full async support
// For now, use the synchronous interface

// Terminal cursor and screen manipulation functions (Node.js compatible)

///| Clear the screen down from cursor position
pub fn clearScreenDown(stream? : String) -> Unit {
  clear_screen_down(_stream=stream)
}

///| Move cursor to specified position
pub fn cursorTo(x : Int, y? : Int, stream? : String) -> Unit {
  cursor_to(x, y~, _stream=stream)
}

///| Move cursor by relative amount
pub fn moveCursor(dx : Int, dy? : Int, stream? : String) -> Unit {
  move_cursor(dx, dy~, _stream=stream)
}

///| Clear current line
pub fn clearLine(dir : Int, stream? : String) -> Unit {
  clear_line(dir, _stream=stream)
}

// Utility functions for working with readline

///| Check if a file descriptor refers to a terminal
pub fn isatty(fd : Int) -> Bool {
  mbt_is_tty(fd)
}

///| Get terminal window size
pub fn getWindowSize() -> (Int, Int)? {
  let rows = Ref::{ val: 0 }
  let cols = Ref::{ val: 0 }
  if mbt_get_window_size(rows, cols) == 0 {
    Some((rows.val, cols.val))
  } else {
    None
  }
}

// High-level convenience functions

///| Simple question-answer interaction
pub fn question(prompt : String, callback : (String) -> Unit) -> Unit {
  let rl = createInterface()
  rl.question(prompt, fn(answer) {
    callback(answer)
    rl.close()
  })
}

///| Async version of simple question (placeholder - not implemented)
pub fn questionAsync(prompt : String) -> String {
  let rl = createInterface()
  defer rl.close()
  // This would be async in a real implementation
  prompt // Placeholder return
}

///| Confirm dialog (y/n)
pub fn confirm(
  message : String,
  callback : (Bool) -> Unit,
  default~ : Bool = false,
) -> Unit {
  let rl = createInterface()
  let suffix = if default { " [Y/n]" } else { " [y/N]" }
  fn ask_again() {
    rl.question(message + suffix + " ", fn(answer) {
      match answer.to_lower() {
        "" => {
          callback(default)
          rl.close()
        }
        "y" | "yes" => {
          callback(true)
          rl.close()
        }
        "n" | "no" => {
          callback(false)
          rl.close()
        }
        _ => {
          rl.write("Please answer yes or no.\n")
          ask_again()
        }
      }
    })
  }

  ask_again()
}

///| Async confirm dialog (placeholder - not implemented)
pub fn confirmAsync(_message : String, default~ : Bool = false) -> Bool {
  // This would be async in a real implementation
  default // Placeholder return
}

///| Read multiple lines until empty line
pub fn readMultipleLines(
  prompt : String,
  callback : (Array[String]) -> Unit,
) -> Unit {
  let rl = createInterface()
  let lines = Array::new()
  fn read_next() {
    rl.question(prompt, fn(line) {
      if line.length() == 0 {
        callback(lines)
        rl.close()
      } else {
        lines.push(line)
        read_next()
      }
    })
  }

  read_next()
}

///| Async version of reading multiple lines (placeholder - not implemented)
pub fn readMultipleLinesAsync(_prompt : String) -> Array[String] {
  // This would be async in a real implementation
  Array::new() // Placeholder return
}

///| Interactive menu selection
pub fn selectFromMenu(
  title : String,
  options : Array[String],
  callback : (Int?) -> Unit,
) -> Unit {
  let rl = createInterface()

  // Display menu
  rl.write(title + "\n")
  for i, option in options {
    rl.write("\{i + 1}. \{option}\n")
  }
  fn ask_selection() {
    rl.question("Select an option (1-\{options.length()}): ", fn(answer) {
      try {
        let choice = @strconv.parse_int(answer)
        if choice >= 1 && choice <= options.length() {
          callback(Some(choice - 1)) // Return 0-based index
          rl.close()
        } else {
          rl.write("Invalid selection. Please try again.\n")
          ask_selection()
        }
      } catch {
        _ => {
          rl.write("Invalid selection. Please try again.\n")
          ask_selection()
        }
      }
    })
  }

  ask_selection()
}

///| Async menu selection (placeholder - not implemented)
pub fn selectFromMenuAsync(_title : String, _options : Array[String]) -> Int? {
  // This would be async in a real implementation
  None // Placeholder return
}

// Advanced readline features

///| Create a readline interface with file completion
pub fn createInterfaceWithFileCompletion(
  input? : String,
  output? : String,
) -> Interface {
  let options = InterfaceOptions::new().with_completer(file_path_completer)
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  create_interface(options)
}

///| Create a readline interface with command completion
pub fn createInterfaceWithCommands(commands : Array[String]) -> Interface {
  let options = InterfaceOptions::new().with_completer(
    command_completer(commands),
  )
  create_interface(options)
}

///| Create a readline interface with custom completion
pub fn createInterfaceWithCompletion(
  completer : CompletionFunction,
  input? : String,
  output? : String,
) -> Interface {
  let options = InterfaceOptions::new().with_completer(completer)
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  create_interface(options)
}

// Password input utility

///|
pub fn password(
  prompt : String,
  callback : (String) -> Unit,
  _mask~ : String = "*",
) -> Unit {
  // Note: This is a simplified implementation
  // A full implementation would need terminal mode manipulation
  let rl = createInterface()
  rl.write(prompt)
  rl.question("", fn(input) {
    callback(input)
    rl.close()
  })
}

///| Async password input (placeholder - not implemented)
pub fn passwordAsync(_prompt : String, _mask~ : String = "*") -> String {
  // This would be async in a real implementation
  "" // Placeholder return
}

// REPL-style interface

///|
pub struct REPL {
  rl : Interface
  mut commands : Map[String, (Array[String]) -> Unit]
  prompt_text : String
}

///|
pub fn REPL::new(prompt~ : String = "> ") -> REPL {
  let rl = createInterface()
  let repl = REPL::{ rl, commands: Map::new(), prompt_text: prompt }
  // Force the use of mutability by reassigning
  repl.commands = Map::new()
  repl
}

///|
pub fn REPL::add_command(
  self : REPL,
  name : String,
  handler : (Array[String]) -> Unit,
) -> REPL {
  self.commands.set(name, handler)
  self
}

///|
pub fn REPL::start(self : REPL) -> Unit {
  self.rl.set_prompt(self.prompt_text)
  self.rl.on_line(fn(line) {
    let parts_iter = line.split(" ")
    let parts = Array::new()
    for part in parts_iter {
      parts.push(part.to_string())
    }
    if parts.length() > 0 {
      let command = parts[0]
      let args = Array::new()
      for i = 1; i < parts.length(); i = i + 1 {
        args.push(parts[i])
      }
      match self.commands.get(command) {
        Some(handler) => handler(args)
        None => println("Unknown command: \{command}")
      }
    }
    self.rl.prompt()
  })
  |> ignore
  self.rl.on_close(fn() { println("Goodbye!") }) |> ignore

  // Start the REPL
  self.rl.prompt()
}

///|
pub fn REPL::close(self : REPL) -> Unit {
  self.rl.close()
}

// Initialize the readline system

///|
pub fn initialize() -> Unit {
  if mbt_readline_init() != 0 {
    panic()
  }
}

// Cleanup function

///|
pub fn cleanup() -> Unit {
  mbt_readline_cleanup()
}

// Import interface functions locally

///|
pub fn clear_screen_down(_stream~ : String?) -> Unit {
  let escape_sequence = "\u001b[0J"
  println(escape_sequence) // Placeholder
}

///|
pub fn cursor_to(x : Int, y~ : Int?, _stream~ : String?) -> Unit {
  let escape_sequence = match y {
    Some(row) => "\u001b[\{row + 1};\{x + 1}H"
    None => "\u001b[\{x + 1}G"
  }
  println(escape_sequence) // Placeholder
}

///|
pub fn move_cursor(dx : Int, dy~ : Int?, _stream~ : String?) -> Unit {
  if dx != 0 {
    let direction = if dx > 0 { "C" } else { "D" }
    let amount = if dx > 0 { dx } else { -dx }
    println("\u001b[\{amount}\{direction}") // Placeholder
  }
  match dy {
    Some(delta) if delta != 0 => {
      let direction = if delta > 0 { "B" } else { "A" }
      let amount = if delta > 0 { delta } else { -delta }
      println("\u001b[\{amount}\{direction}") // Placeholder
    }
    _ => ()
  }
}

///|
pub fn clear_line(dir : Int, _stream~ : String?) -> Unit {
  let escape_sequence = match dir {
    0 => "\u001b[2K" // Clear entire line
    1 => "\u001b[1K" // Clear from cursor to beginning
    -1 => "\u001b[0K" // Clear from cursor to end
    _ => "\u001b[2K" // Default to clear entire line
  }
  println(escape_sequence) // Placeholder
}

// Note: FFI declarations moved to ffi.mbt file
// These functions are placeholders for wasm-gc backend

///|
fn mbt_is_tty(_fd : Int) -> Bool {
  false // Placeholder implementation
}

///|
fn mbt_get_window_size(rows : Ref[Int], cols : Ref[Int]) -> Int {
  rows.val = 24
  cols.val = 80
  0
}

///|
fn mbt_readline_init() -> Int {
  0 // Success
}

///|
fn mbt_readline_cleanup() -> Unit {
  // Placeholder cleanup
}
