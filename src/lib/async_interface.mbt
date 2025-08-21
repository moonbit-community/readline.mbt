// Async readline interface for use with MoonBit's async runtime

// Note: This is a conceptual implementation for when MoonBit has full async support
// Currently using simplified synchronous version

// Async version of the Interface that integrates with MoonBit's event loop
pub struct AsyncInterface {
  interface : Interface
  mut question_queue : Array[(String, (String) -> Unit)]
  mut is_processing : Bool
}

impl AsyncInterface {
  pub fn new(options: InterfaceOptions) -> AsyncInterface {
    let interface = Interface::new(options)
    AsyncInterface::{
      interface,
      question_queue: Array::new(),
      is_processing: false
    }
  }

  // Async question method that works with MoonBit's async system
  pub fn question_async(self: Self, query: String, callback: (String) -> Unit) -> Unit {
    if self.interface.closed() {
      raise "Interface is closed"
    }

    // Create a promise-like structure using async/await
    let mut result : String? = None
    let mut finished = false

    // Set up the callback
    let callback = fn(answer: String) {
      result = Some(answer)
      finished = true
    }

    // Add to queue
    self.question_queue.push((query, callback))
    
    // Process the queue if not already processing
    if not(self.is_processing) {
      self.process_question_queue()
    }

    // Wait for the result using async polling
    while not(finished) {
      @async.pause()
    }

    match result {
      Some(answer) => answer
      None => raise "Failed to get answer"
    }
  }

  async fn process_question_queue(self: Self) -> Unit raise {
    if self.is_processing || self.question_queue.length() == 0 {
      return
    }

    self.is_processing = true

    while self.question_queue.length() > 0 {
      let (query, callback) = self.question_queue.remove(0)
      
      // Set up one-time line listener
      self.interface.once("line", fn(event) {
        match event {
          Line(answer) => callback(answer)
          _ => ()
        }
      })

      // Display the query and wait for input
      self.interface.write(query)
      
      // In an async context, we need to wait for input without blocking
      await self.wait_for_input()
    }

    self.is_processing = false
  }

  async fn wait_for_input(self: Self) -> Unit raise {
    // Non-blocking wait for input
    while not(mbt_readline_input_available()) {
      @async.sleep(10) // Check every 10ms
      if self.interface.closed() {
        return
      }
    }

    // Input is available, read it
    let line = mbt_readline_read_line_mbt(self.interface.get_prompt())
    if line.length() > 0 {
      self.interface.events.emit_line(line) |> ignore
      
      // Add to history
      mbt_readline_add_history(string_to_c_bytes(line))
    }
  }

  // Async prompt method
  pub async fn prompt(self: Self, preserve_cursor~: Bool = false) -> Unit raise {
    if self.interface.closed() || self.interface.paused() {
      return
    }

    await self.wait_for_input()
  }

  // Event stream methods for async processing
  pub async fn read_lines(self: Self) -> Array[String] raise {
    let lines = Array::new()
    let mut should_continue = true

    // Set up line listener
    self.interface.on_line(fn(line) {
      lines.push(line)
    })

    // Set up close listener
    self.interface.once("close", fn() {
      should_continue = false
    })

    // Process input until closed
    while should_continue && not(self.interface.closed()) {
      if mbt_readline_input_available() {
        await self.wait_for_input()
      } else {
        @async.sleep(10)
      }
    }

    lines
  }

  // Async iterator-like functionality
  pub async fn for_each_line(self: Self, handler: (String) -> Unit) -> Unit raise {
    self.interface.on_line(handler)
    
    while not(self.interface.closed()) {
      if mbt_readline_input_available() {
        await self.wait_for_input()
      } else {
        @async.sleep(10)
      }
    }
  }

  // Delegate methods to the synchronous interface
  pub fn write(self: Self, data: String, key~: String? = None) -> Unit {
    self.interface.write(data, key~)
  }

  pub fn pause(self: Self) -> Self {
    self.interface.pause() |> ignore
    self
  }

  pub fn resume(self: Self) -> Self {
    self.interface.resume() |> ignore
    self
  }

  pub fn close(self: Self) -> Unit {
    self.interface.close()
  }

  pub fn set_prompt(self: Self, prompt: String) -> Unit {
    self.interface.set_prompt(prompt)
  }

  pub fn get_prompt(self: Self) -> String {
    self.interface.get_prompt()
  }

  pub fn clear_history(self: Self) -> Unit {
    self.interface.clear_history()
  }

  // Event delegation
  pub fn on(self: Self, event: String, listener: EventListener[ReadlineEvent]) -> Self {
    self.interface.on(event, listener)
    self
  }

  pub fn once(self: Self, event: String, listener: EventListener[ReadlineEvent]) -> Self {
    self.interface.once(event, listener)
    self
  }

  pub fn off(self: Self, event: String, listener: EventListener[ReadlineEvent]) -> Self {
    self.interface.off(event, listener)
    self
  }

  pub fn on_line(self: Self, listener: (String) -> Unit) -> Self {
    self.interface.on_line(listener)
    self
  }

  pub fn on_close(self: Self, listener: () -> Unit) -> Self {
    self.interface.on_close(listener)
    self
  }

  pub fn on_sigint(self: Self, listener: () -> Unit) -> Self {
    self.interface.on_sigint(listener)
    self
  }

  // Properties
  pub fn closed(self: Self) -> Bool {
    self.interface.closed()
  }

  pub fn paused(self: Self) -> Bool {
    self.interface.paused()
  }

  pub fn terminal(self: Self) -> Bool {
    self.interface.terminal()
  }
}

// Async module-level functions
pub async fn create_async_interface(options: InterfaceOptions) -> AsyncInterface raise {
  AsyncInterface::new(options)
}

pub async fn create_async_interface_simple(input?: String, output?: String) -> AsyncInterface raise {
  let options = InterfaceOptions::new()
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  AsyncInterface::new(options)
}

// Async utility functions for common readline patterns
pub async fn async_question(rl: AsyncInterface, query: String) -> String raise {
  await rl.question(query)
}

// Read multiple lines until a specific condition
pub async fn read_lines_until(
  rl: AsyncInterface, 
  condition: (String) -> Bool
) -> Array[String] raise {
  let lines = Array::new()
  
  while not(rl.closed()) {
    let line = await rl.question("")
    lines.push(line)
    
    if condition(line) {
      break
    }
  }
  
  lines
}

// Read lines with a timeout
pub async fn question_with_timeout(
  rl: AsyncInterface,
  query: String,
  timeout_ms: Int
) -> String? raise {
  try {
    let result = @async.with_timeout(timeout_ms, fn() {
      await rl.question(query)
    })
    Some(result)
  } catch {
    _ => None
  }
}

// Interactive menu selection
pub async fn select_from_menu(
  rl: AsyncInterface,
  title: String,
  options: Array[String]
) -> Int? raise {
  // Display menu
  rl.write(title + "\n")
  for i, option in options {
    rl.write("\{i + 1}. \{option}\n")
  }
  
  while true {
    let answer = await rl.question("Select an option (1-\{options.length()}): ")
    
    match answer.trim().parse_int() {
      Ok(choice) if choice >= 1 && choice <= options.length() => {
        return Some(choice - 1) // Return 0-based index
      }
      _ => {
        rl.write("Invalid selection. Please try again.\n")
      }
    }
  }
  
  None
}

// Confirm dialog
pub async fn confirm(
  rl: AsyncInterface,
  message: String,
  default~: Bool = false
) -> Bool raise {
  let suffix = if default { " [Y/n]" } else { " [y/N]" }
  let answer = await rl.question(message + suffix + " ")
  
  match answer.trim().to_lower() {
    "" => default
    "y" | "yes" => true
    "n" | "no" => false
    _ => await confirm(rl, "Please answer yes or no.", default~)
  }
}

// Password input (hide characters)
pub async fn password(
  rl: AsyncInterface,
  query: String,
  mask~: String = "*"
) -> String raise {
  // Note: This is a simplified implementation
  // A full implementation would need to handle terminal modes
  // and character masking at a lower level
  
  rl.write(query)
  // For now, just read normally - a full implementation would
  // disable echo and show mask characters
  let password = await rl.question("")
  password
}