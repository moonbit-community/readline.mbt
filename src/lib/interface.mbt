// Readline Interface implementation compatible with Node.js readline

// Interface options (matching Node.js readline)

///|
pub struct InterfaceOptions {
  input : String? // Input stream (file path or "stdin")
  output : String? // Output stream (file path or "stdout")  
  completer : ((String) -> (Array[String], String))? // Completion function
  terminal : Bool? // Force terminal mode
  history_size : Int? // Maximum history entries
  prompt : String? // Default prompt
  cr_lf_delay : Int? // Delay between \r and \n
  escape_code_timeout : Int? // Timeout for escape sequences
  tab_size : Int? // Tab size for completion display
  remove_history_duplicates : Bool? // Remove duplicate history entries
}

///|
fn InterfaceOptions::new() -> InterfaceOptions {
  InterfaceOptions::{
    input: None,
    output: None,
    completer: None,
    terminal: None,
    history_size: None,
    prompt: None,
    cr_lf_delay: None,
    escape_code_timeout: None,
    tab_size: None,
    remove_history_duplicates: None,
  }
}

///|
fn InterfaceOptions::with_input(
  self : InterfaceOptions,
  input : String,
) -> InterfaceOptions {
  InterfaceOptions::{
    input: Some(input),
    output: self.output,
    completer: self.completer,
    terminal: self.terminal,
    history_size: self.history_size,
    prompt: self.prompt,
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

///|
fn InterfaceOptions::with_output(
  self : InterfaceOptions,
  output : String,
) -> InterfaceOptions {
  InterfaceOptions::{
    input: self.input,
    output: Some(output),
    completer: self.completer,
    terminal: self.terminal,
    history_size: self.history_size,
    prompt: self.prompt,
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

///|
fn InterfaceOptions::with_completer(
  self : InterfaceOptions,
  completer : (String) -> (Array[String], String),
) -> InterfaceOptions {
  InterfaceOptions::{
    input: self.input,
    output: self.output,
    completer: Some(completer),
    terminal: self.terminal,
    history_size: self.history_size,
    prompt: self.prompt,
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

///|
fn InterfaceOptions::with_terminal(
  self : InterfaceOptions,
  terminal : Bool,
) -> InterfaceOptions {
  InterfaceOptions::{
    input: self.input,
    output: self.output,
    completer: self.completer,
    terminal: Some(terminal),
    history_size: self.history_size,
    prompt: self.prompt,
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

///|
fn InterfaceOptions::with_history_size(
  self : InterfaceOptions,
  size : Int,
) -> InterfaceOptions {
  InterfaceOptions::{
    input: self.input,
    output: self.output,
    completer: self.completer,
    terminal: self.terminal,
    history_size: Some(size),
    prompt: self.prompt,
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

///|
fn InterfaceOptions::with_prompt(
  self : InterfaceOptions,
  prompt : String,
) -> InterfaceOptions {
  InterfaceOptions::{
    input: self.input,
    output: self.output,
    completer: self.completer,
    terminal: self.terminal,
    history_size: self.history_size,
    prompt: Some(prompt),
    cr_lf_delay: self.cr_lf_delay,
    escape_code_timeout: self.escape_code_timeout,
    tab_size: self.tab_size,
    remove_history_duplicates: self.remove_history_duplicates,
  }
}

// The main Interface class

///|
pub struct Interface {
  mut events : ReadlineEventEmitter
  mut prompt_text : String
  mut is_paused : Bool
  mut is_closed : Bool
  mut history_max_size : Int
  mut completer : ((String) -> (Array[String], String))?
  mut remove_duplicates : Bool
  input_path : String
  output_path : String
  is_terminal : Bool
}

///|
fn Interface::new(options : InterfaceOptions) -> Interface {
  let interface = Interface::{
    events: ReadlineEventEmitter::create(),
    prompt_text: match options.prompt {
      Some(p) => p
      None => "> "
    },
    is_paused: false,
    is_closed: false,
    history_max_size: match options.history_size {
      Some(s) => s
      None => 1000
    },
    completer: options.completer,
    remove_duplicates: match options.remove_history_duplicates {
      Some(r) => r
      None => true
    },
    input_path: match options.input {
      Some(i) => i
      None => "stdin"
    },
    output_path: match options.output {
      Some(o) => o
      None => "stdout"
    },
    is_terminal: match options.terminal {
      Some(t) => t
      None => true
    },
  }

  // Initialize the native readline
  if mbt_readline_init() != 0 {
    panic()
  }

  // Set history size
  mbt_readline_set_history_size(interface.history_max_size)

  // Set prompt
  mbt_readline_set_prompt(string_to_c_bytes(interface.prompt_text))

  // Setup signal handlers
  interface.setup_signal_handlers()
  interface
}

///|
fn Interface::setup_signal_handlers(self : Interface) -> Unit {
  // SIGINT handler
  let sigint_handler : FuncRef[() -> Unit] = fn() {
    self.events.emit_sigint() |> ignore
  }
  mbt_readline_set_sigint_callback(sigint_handler)

  // SIGTSTP handler
  let sigtstp_handler : FuncRef[() -> Unit] = fn() {
    self.events.emit_sigtstp() |> ignore
  }
  mbt_readline_set_sigtstp_callback(sigtstp_handler)

  // SIGCONT handler
  let sigcont_handler : FuncRef[() -> Unit] = fn() {
    self.events.emit_sigcont() |> ignore
  }
  mbt_readline_set_sigcont_callback(sigcont_handler)

  // Close handler
  let close_handler : FuncRef[() -> Unit] = fn() {
    self.is_closed = true
    self.events.emit_close() |> ignore
  }
  mbt_readline_set_close_callback(close_handler)
}

// Main interface methods (Node.js compatible)

///|
fn Interface::question(
  self : Interface,
  query : String,
  callback : (String) -> Unit,
) -> Unit {
  if self.is_closed {
    return
  }

  // Setup one-time line listener
  self.events.once(
    "line",
    EventListener(fn(event) {
      match event {
        Line(answer) => callback(answer)
        _ => ()
      }
    }),
  )

  // Prompt for input
  self.prompt(preserve_cursor=false)
}

///|
fn Interface::prompt(self : Interface, preserve_cursor~ : Bool = false) -> Unit {
  if self.is_closed || self.is_paused {
    return
  }

  // Write prompt and read line in a blocking manner
  // In a real async implementation, this would be handled differently
  let line = mbt_readline_read_line_mbt(self.prompt_text)
  if line.length() > 0 {
    self.events.emit_line(line) |> ignore

    // Add to history if not duplicate or if duplicates are allowed
    if not(self.remove_duplicates) || not(self.is_duplicate_history(line)) {
      mbt_readline_add_history(string_to_c_bytes(line))
    }
  }
}

///|
fn Interface::write(
  self : Interface,
  data : String,
  key~ : String? = None,
) -> Unit {
  if self.is_closed {
    return
  }
  let output = match key {
    Some(k) => data + k
    None => data
  }
  mbt_readline_write(string_to_c_bytes(output))
}

///|
fn Interface::pause(self : Interface) -> Interface {
  if not(self.is_closed) && not(self.is_paused) {
    self.is_paused = true
    mbt_readline_pause()
    self.events.emit_pause() |> ignore
  }
  self
}

///|
fn Interface::resume(self : Interface) -> Interface {
  if not(self.is_closed) && self.is_paused {
    self.is_paused = false
    mbt_readline_resume()
    self.events.emit_resume() |> ignore
  }
  self
}

///|
fn Interface::close(self : Interface) -> Unit {
  if not(self.is_closed) {
    self.is_closed = true
    mbt_readline_close()
    self.events.emit_close() |> ignore
  }
}

// Prompt management

///|
fn Interface::set_prompt(self : Interface, prompt : String) -> Unit {
  self.prompt_text = prompt
  mbt_readline_set_prompt(string_to_c_bytes(prompt))
}

///|
fn Interface::get_prompt(self : Interface) -> String {
  self.prompt_text
}

// History management

///|
fn Interface::clear_history(self : Interface) -> Unit {
  mbt_readline_clear_history()
}

///|
fn Interface::is_duplicate_history(self : Interface, line : String) -> Bool {
  let history_len = mbt_readline_history_length()
  if history_len == 0 {
    return false
  }

  // Check if the last history entry is the same
  let last_entry = mbt_readline_get_history(history_len - 1)
  // Note: We need to implement CString comparison
  line == last_entry.to_string()
}

// Event emitter delegation

///|
fn Interface::on(
  self : Interface,
  event : String,
  listener : EventListener[ReadlineEvent],
) -> Interface {
  self.events.on(event, listener) |> ignore
  self
}

///|
fn Interface::once(
  self : Interface,
  event : String,
  listener : EventListener[ReadlineEvent],
) -> Interface {
  self.events.once(event, listener) |> ignore
  self
}

///|
fn Interface::off(
  self : Interface,
  event : String,
  listener : EventListener[ReadlineEvent],
) -> Interface {
  self.events.off(event, listener) |> ignore
  self
}

///|
fn Interface::emit(
  self : Interface,
  event : String,
  data : ReadlineEvent,
) -> Bool {
  self.events.emit(event, data)
}

///|
fn Interface::emit_line(self : Interface, line : String) -> Bool {
  self.events.emit_line(line)
}

///|
fn Interface::remove_all_listeners(
  self : Interface,
  event~ : String?,
) -> Interface {
  self.events.remove_all_listeners(event~) |> ignore
  self
}

///|
fn Interface::listener_count(self : Interface, event : String) -> Int {
  self.events.listener_count(event)
}

///|
fn Interface::event_names(self : Interface) -> Array[String] {
  self.events.event_names()
}

// Convenience event methods

///|
fn Interface::on_line(
  self : Interface,
  listener : (String) -> Unit,
) -> Interface {
  self.events.on_line(listener) |> ignore
  self
}

///|
fn Interface::on_close(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_close(listener) |> ignore
  self
}

///|
fn Interface::on_pause(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_pause(listener) |> ignore
  self
}

///|
fn Interface::on_resume(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_resume(listener) |> ignore
  self
}

///|
fn Interface::on_sigint(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_sigint(listener) |> ignore
  self
}

///|
fn Interface::on_sigtstp(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_sigtstp(listener) |> ignore
  self
}

///|
fn Interface::on_sigcont(self : Interface, listener : () -> Unit) -> Interface {
  self.events.on_sigcont(listener) |> ignore
  self
}

// Properties (Node.js compatible)

///|
fn Interface::closed(self : Interface) -> Bool {
  self.is_closed
}

///|
fn Interface::paused(self : Interface) -> Bool {
  self.is_paused
}

///|
fn Interface::terminal(self : Interface) -> Bool {
  self.is_terminal
}

// Module-level functions (Node.js compatible)

///|
pub fn create_interface(options : InterfaceOptions) -> Interface {
  Interface::new(options)
}

// Convenience function with minimal options

///|
pub fn create_interface_simple(
  input~ : String?,
  output~ : String?,
) -> Interface {
  let options = InterfaceOptions::new()
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

// Clear the entire screen

///|
pub fn clear_screen_down(stream~ : String?) -> Unit {
  let escape_sequence = "\x1b[0J"
  mbt_readline_write(string_to_c_bytes(escape_sequence))
}

// Placeholder implementations for missing functions

///|
fn mbt_readline_init() -> Int {
  0 // Success
}

///|
fn mbt_readline_set_history_size(size : Int) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_set_prompt(prompt : Bytes) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_set_sigint_callback(callback : FuncRef[() -> Unit]) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_set_sigtstp_callback(callback : FuncRef[() -> Unit]) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_set_sigcont_callback(callback : FuncRef[() -> Unit]) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_set_close_callback(callback : FuncRef[() -> Unit]) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_read_line_mbt(prompt : String) -> String {
  prompt // Placeholder - just return the prompt
}

///|
fn mbt_readline_add_history(line : Bytes) -> Unit {
  // Placeholder
}

///|
fn mbt_readline_pause() -> Unit {
  // Placeholder
}

///|
fn mbt_readline_resume() -> Unit {
  // Placeholder
}

///|
fn mbt_readline_close() -> Unit {
  // Placeholder
}

///|
fn mbt_readline_clear_history() -> Unit {
  // Placeholder
}

///|
fn mbt_readline_history_length() -> Int {
  0 // Placeholder
}

///|
fn mbt_readline_get_history(index : Int) -> CString {
  // Need to create a placeholder CString
  create_empty_cstring()
}

///|
fn mbt_readline_write(data : Bytes) -> Unit {
  // Placeholder
}

///|
fn string_to_c_bytes(s : String) -> Bytes {
  s.to_bytes()
}

// CString implementation

///|
#extern
type CString

///|
fn CString::to_string(self : CString) -> String {
  "" // Placeholder
}

///|
fn create_empty_cstring() -> CString {
  // This would need proper FFI implementation
  panic() // Placeholder that will fail if called
}

// Move cursor to specified position

///|
pub fn cursor_to(x : Int, y~ : Int?, stream~ : String?) -> Unit {
  let escape_sequence = match y {
    Some(row) => "\x1b[\{row + 1};\{x + 1}H"
    None => "\x1b[\{x + 1}G"
  }
  mbt_readline_write(string_to_c_bytes(escape_sequence))
}

// Move cursor relatively

///|
pub fn move_cursor(dx : Int, dy~ : Int?, stream~ : String?) -> Unit {
  if dx != 0 {
    let direction = if dx > 0 { "C" } else { "D" }
    let amount = if dx > 0 { dx } else { -dx }
    mbt_readline_write(string_to_c_bytes("\x1b[\{amount}\{direction}"))
  }
  match dy {
    Some(delta) if delta != 0 => {
      let direction = if delta > 0 { "B" } else { "A" }
      let amount = if delta > 0 { delta } else { -delta }
      mbt_readline_write(string_to_c_bytes("\x1b[\{amount}\{direction}"))
    }
    _ => ()
  }
}

// Clear specified number of lines

///|
pub fn clear_line(dir : Int, stream~ : String?) -> Unit {
  let escape_sequence = match dir {
    0 => "\x1b[2K" // Clear entire line
    1 => "\x1b[1K" // Clear from cursor to beginning
    -1 => "\x1b[0K" // Clear from cursor to end
    _ => "\x1b[2K" // Default to clear entire line
  }
  mbt_readline_write(string_to_c_bytes(escape_sequence))
}
