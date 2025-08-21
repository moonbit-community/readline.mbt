// Main readline module - Node.js compatible interface

// Re-export all public types and functions for a clean API
pub use events::{ EventEmitter, EventListener, ReadlineEvent, ReadlineEventEmitter }
pub use interface::{ Interface, InterfaceOptions, create_interface, create_interface_simple }
pub use history::{ History, Completer, CompletionFunction }

// Main readline module functions (Node.js compatible)

///| Create a readline interface with specified options
///| This is the main entry point for creating readline interfaces
pub fn createInterface(options: InterfaceOptions) -> Interface {
  create_interface(options)
}

///| Create a simple readline interface with just input/output streams
pub fn createInterface(input?: String, output?: String) -> Interface {
  create_interface_simple(input~, output~)
}

// Note: Async interfaces would be available when MoonBit has full async support
// For now, use the synchronous interface

// Terminal cursor and screen manipulation functions (Node.js compatible)

///| Clear the screen down from cursor position
pub fn clearScreenDown(stream?: String) -> Unit {
  interface::clear_screen_down(stream~)
}

///| Move cursor to specified position
pub fn cursorTo(x: Int, y?: Int, stream?: String) -> Unit {
  interface::cursor_to(x, y~, stream~)
}

///| Move cursor by relative amount
pub fn moveCursor(dx: Int, dy?: Int, stream?: String) -> Unit {
  interface::move_cursor(dx, dy~, stream~)
}

///| Clear current line
pub fn clearLine(dir: Int, stream?: String) -> Unit {
  interface::clear_line(dir, stream~)
}

// Utility functions for working with readline

///| Check if a file descriptor refers to a terminal
pub fn isatty(fd: Int) -> Bool {
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
pub fn question(prompt: String, callback: (String) -> Unit) -> Unit {
  let rl = createInterface()
  rl.question(prompt, fn(answer) {
    callback(answer)
    rl.close()
  })
}

///| Async version of simple question
pub async fn questionAsync(prompt: String) -> String raise {
  let rl = await createAsyncInterface()
  defer rl.close()
  await rl.question(prompt)
}

///| Confirm dialog (y/n)
pub fn confirm(message: String, callback: (Bool) -> Unit, default~: Bool = false) -> Unit {
  let rl = createInterface()
  let suffix = if default { " [Y/n]" } else { " [y/N]" }
  
  fn ask_again() {
    rl.question(message + suffix + " ", fn(answer) {
      match answer.trim().to_lower() {
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

///| Async confirm dialog
pub async fn confirmAsync(message: String, default~: Bool = false) -> Bool raise {
  await async_interface::confirm(await createAsyncInterface(), message, default~)
}

///| Read multiple lines until empty line
pub fn readMultipleLines(prompt: String, callback: (Array[String]) -> Unit) -> Unit {
  let rl = createInterface()
  let lines = Array::new()
  
  fn read_next() {
    rl.question(prompt, fn(line) {
      if line.trim().length() == 0 {
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

///| Async version of reading multiple lines
pub async fn readMultipleLinesAsync(prompt: String) -> Array[String] raise {
  let rl = await createAsyncInterface()
  defer rl.close()
  
  await async_interface::read_lines_until(rl, fn(line) { line.trim().length() == 0 })
}

///| Interactive menu selection
pub fn selectFromMenu(
  title: String, 
  options: Array[String], 
  callback: (Int?) -> Unit
) -> Unit {
  let rl = createInterface()
  
  // Display menu
  rl.write(title + "\n")
  for i, option in options {
    rl.write("\{i + 1}. \{option}\n")
  }
  
  fn ask_selection() {
    rl.question("Select an option (1-\{options.length()}): ", fn(answer) {
      match answer.trim().parse_int() {
        Ok(choice) if choice >= 1 && choice <= options.length() => {
          callback(Some(choice - 1)) // Return 0-based index
          rl.close()
        }
        _ => {
          rl.write("Invalid selection. Please try again.\n")
          ask_selection()
        }
      }
    })
  }
  
  ask_selection()
}

///| Async menu selection
pub async fn selectFromMenuAsync(title: String, options: Array[String]) -> Int? raise {
  await async_interface::select_from_menu(await createAsyncInterface(), title, options)
}

// Advanced readline features

///| Create a readline interface with file completion
pub fn createInterfaceWithFileCompletion(input?: String, output?: String) -> Interface {
  let options = InterfaceOptions::new()
    .with_completer(history::file_path_completer)
  
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  
  createInterface(options)
}

///| Create a readline interface with command completion
pub fn createInterfaceWithCommands(commands: Array[String]) -> Interface {
  let options = InterfaceOptions::new()
    .with_completer(history::command_completer(commands))
    
  createInterface(options)
}

///| Create a readline interface with custom completion
pub fn createInterfaceWithCompletion(
  completer: CompletionFunction,
  input?: String,
  output?: String
) -> Interface {
  let options = InterfaceOptions::new()
    .with_completer(completer)
    
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  
  createInterface(options)
}

// Password input utility
pub fn password(prompt: String, callback: (String) -> Unit, mask~: String = "*") -> Unit {
  // Note: This is a simplified implementation
  // A full implementation would need terminal mode manipulation
  let rl = createInterface()
  rl.write(prompt)
  rl.question("", fn(input) {
    callback(input)
    rl.close()
  })
}

///| Async password input
pub async fn passwordAsync(prompt: String, mask~: String = "*") -> String raise {
  await async_interface::password(await createAsyncInterface(), prompt, mask~)
}

// REPL-style interface
pub struct REPL {
  rl : Interface
  mut commands : Map[String, (Array[String]) -> Unit]
  prompt_text : String
}

impl REPL {
  pub fn new(prompt~: String = "> ") -> REPL {
    let rl = createInterface()
    REPL::{
      rl,
      commands: Map::new(),
      prompt_text: prompt
    }
  }

  pub fn add_command(self: Self, name: String, handler: (Array[String]) -> Unit) -> Self {
    self.commands.set(name, handler)
    self
  }

  pub fn start(self: Self) -> Unit {
    self.rl.set_prompt(self.prompt_text)
    
    self.rl.on_line(fn(line) {
      let parts = line.trim().split(' ')
      if parts.length() > 0 {
        let command = parts[0]
        let args = parts[1:]
        
        match self.commands.get(command) {
          Some(handler) => handler(args)
          None => println("Unknown command: \{command}")
        }
      }
      
      self.rl.prompt()
    })
    
    self.rl.on_close(fn() {
      println("Goodbye!")
    })
    
    // Start the REPL
    self.rl.prompt()
  }

  pub fn close(self: Self) -> Unit {
    self.rl.close()
  }
}

// Initialize the readline system
fn init() -> Unit {
  if mbt_readline_init() != 0 {
    panic("Failed to initialize readline system")
  }
}

// Cleanup function
pub fn cleanup() -> Unit {
  mbt_readline_cleanup()
}

// Auto-initialize on module load
let _ = init()