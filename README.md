# MoonBit Readline

A complete Node.js readline-compatible library for MoonBit, providing powerful terminal input capabilities with full async support.

## Features

- **100% Node.js readline API compatibility**
- **Async/await support** with MoonBit's async runtime
- **Event-driven architecture** with EventEmitter pattern
- **Advanced line editing** with GNU readline backend
- **History management** with search and navigation
- **Tab completion** with customizable completion functions
- **Signal handling** (SIGINT, SIGTSTP, SIGCONT)
- **Terminal manipulation** (cursor control, screen clearing)
- **Cross-platform support** (Linux, macOS, Windows with appropriate readline library)

## Installation

Add this library to your MoonBit project:

```bash
moon add moonbit-readline
```

### 🚀 Automatic Configuration

This library uses intelligent detection scripts to automatically configure the readline library:

- ✅ **When readline library is found**: Full functionality is used
- ⚠️ **When not found**: Automatically uses mock implementation (limited functionality)

### Recommended: Install readline library

For the best experience, it is recommended to install the GNU readline library:

#### macOS
```bash
brew install readline pkg-config
```

#### Ubuntu/Debian
```bash
sudo apt-get install libreadline-dev libncurses5-dev pkg-config
```

#### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL
sudo yum install readline-devel ncurses-devel pkgconfig
# Fedora
sudo dnf install readline-devel ncurses-devel pkgconfig
```

#### Windows
```bash
# 使用 MSYS2
pacman -S mingw-w64-x86_64-readline mingw-w64-x86_64-ncurses
```

### Manual Configuration

If automatic detection fails, you can set environment variables:

```bash
export READLINE_ROOT=/path/to/readline
# or
export READLINE_INCLUDE_PATH=/path/to/readline/include
export READLINE_LIB_PATH=/path/to/readline/lib
```

For detailed installation guide, please refer to [INSTALL.md](INSTALL.md)

## Quick Start

### Basic Usage

```moonbit
fn main {
  let rl = @readline.createInterface()
  
  rl.question("What's your name? ", fn(name) {
    println("Hello, \{name}!")
    rl.close()
  })
}
```

### Async Usage

```moonbit
fn main {
  @async.with_event_loop(fn(_) {
    run_async_example()
  }) catch { _ => () }
}

async fn run_async_example() -> Unit raise {
  let name = await @readline.questionAsync("What's your name? ")
  println("Hello, \{name}!")
}
```

## API Reference

### Creating Interfaces

#### `createInterface(options: InterfaceOptions) -> Interface`

Creates a readline interface with specified options.

```moonbit
let options = InterfaceOptions::new()
  .with_input("stdin")
  .with_output("stdout")
  .with_prompt("> ")
  .with_history_size(1000)
  .with_completer(my_completer)

let rl = @readline.createInterface(options)
```

#### `createInterface(input?: String, output?: String) -> Interface`

Simple interface creation.

```moonbit
let rl = @readline.createInterface(input="stdin", output="stdout")
```

### Interface Methods

#### `question(query: String, callback: (String) -> Unit) -> Unit`

Ask a question and get user input.

```moonbit
rl.question("Enter your age: ", fn(age) {
  println("You are \{age} years old")
})
```

#### `prompt(preserve_cursor~: Bool = false) -> Unit`

Display the prompt and wait for input.

```moonbit
rl.set_prompt("custom> ")
rl.prompt()
```

#### `write(data: String, key~: String? = None) -> Unit`

Write data to the output stream.

```moonbit
rl.write("Output text\n")
```

#### `pause() -> Self` / `resume() -> Self`

Pause or resume the interface.

```moonbit
rl.pause()   // Pause input processing
rl.resume()  // Resume input processing
```

#### `close() -> Unit`

Close the interface and clean up resources.

```moonbit
rl.close()
```

### Event Handling

The interface implements the EventEmitter pattern, compatible with Node.js:

```moonbit
// Line input event
rl.on_line(fn(line) {
  println("Input: \{line}")
})

// Interface closed
rl.on_close(fn() {
  println("Goodbye!")
})

// Signal events
rl.on_sigint(fn() {
  println("Ctrl+C pressed")
})

rl.on_sigtstp(fn() {
  println("Ctrl+Z pressed")
})
```

### Async Interface

The async interface provides promise-based methods:

```moonbit
async fn interactive_session() -> Unit raise {
  let rl = await @readline.createAsyncInterface()
  defer rl.close()
  
  let name = await rl.question("Name: ")
  let age = await rl.question("Age: ")
  
  println("Hello \{name}, age \{age}!")
}
```

### Utility Functions

#### `questionAsync(prompt: String) -> String`

Simple async question (creates and closes interface automatically).

```moonbit
let name = await @readline.questionAsync("Your name: ")
```

#### `confirmAsync(message: String, default~: Bool = false) -> Bool`

Async confirmation dialog.

```moonbit
let confirmed = await @readline.confirmAsync("Continue?", default=true)
```

#### `selectFromMenuAsync(title: String, options: Array[String]) -> Int?`

Async menu selection.

```moonbit
let options = ["Option A", "Option B", "Option C"]
let choice = await @readline.selectFromMenuAsync("Select:", options)
```

### Completion

Create custom completion functions:

```moonbit
fn my_completer(word: String) -> (Array[String], String) {
  let completions = ["hello", "help", "history", "exit"]
  let matches = Array::new()
  
  for completion in completions {
    if completion.starts_with(word) {
      matches.push(completion)
    }
  }
  
  (matches, word)
}

let rl = @readline.createInterfaceWithCompletion(my_completer)
```

Built-in completers:

```moonbit
// File path completion
let rl = @readline.createInterfaceWithFileCompletion()

// Command completion
let commands = ["help", "list", "create", "delete"]
let rl = @readline.createInterfaceWithCommands(commands)
```

### History Management

```moonbit
// Clear history
rl.clear_history()

// Get history length
let len = mbt_readline_history_length()

// Set history size
let options = InterfaceOptions::new().with_history_size(500)
```

### Terminal Manipulation

```moonbit
// Move cursor to position
@readline.cursorTo(10, 5)

// Move cursor relatively
@readline.moveCursor(2, -1)

// Clear line
@readline.clearLine(0)  // entire line
@readline.clearLine(1)  // from cursor to beginning
@readline.clearLine(-1) // from cursor to end

// Clear screen down
@readline.clearScreenDown()
```

### REPL Creation

```moonbit
let repl = @readline.REPL::new("my-app> ")

repl
  .add_command("hello", fn(args) {
    println("Hello \{args.get(0).or("World")}!")
  })
  .add_command("exit", fn(_) {
    repl.close()
  })

repl.start()
```

## Examples

### Interactive Form

```moonbit
async fn user_form() -> Unit raise {
  let rl = await @readline.createAsyncInterface()
  defer rl.close()
  
  let name = await rl.question("Full name: ")
  let email = await rl.question("Email: ")
  
  // Validate age input
  let mut age = 0
  while true {
    let age_str = await rl.question("Age: ")
    match age_str.parse_int() {
      Ok(parsed_age) if parsed_age > 0 => {
        age = parsed_age
        break
      }
      _ => rl.write("Please enter a valid age.\n")
    }
  }
  
  let confirmed = await @readline.confirmAsync("Is this information correct?")
  
  if confirmed {
    println("User registered: \{name}, \{email}, \{age}")
  } else {
    println("Registration cancelled")
  }
}
```

### Command Line Tool

```moonbit
fn main {
  let rl = @readline.createInterfaceWithCommands([
    "list", "create", "delete", "help", "exit"
  ])
  
  rl.on_line(fn(line) {
    let parts = line.trim().split(' ')
    let command = parts[0]
    let args = parts[1:]
    
    match command {
      "list" => list_items()
      "create" => create_item(args)
      "delete" => delete_item(args)
      "help" => show_help()
      "exit" => rl.close()
      "" => rl.prompt()
      _ => {
        println("Unknown command: \{command}")
        rl.prompt()
      }
    }
  })
  
  println("Welcome! Type 'help' for available commands.")
  rl.prompt()
}
```

## Node.js Compatibility

This library is designed to be a drop-in replacement for Node.js readline. Here's a comparison:

### Node.js Code
```javascript
const readline = require('readline');

const rl = readline.createInterface({
  input: process.stdin,
  output: process.stdout,
  prompt: 'test> '
});

rl.on('line', (input) => {
  console.log(`Received: ${input}`);
  rl.prompt();
});

rl.question('What is your name? ', (name) => {
  console.log(`Hello ${name}!`);
  rl.close();
});
```

### MoonBit Code
```moonbit
let options = InterfaceOptions::new()
  .with_input("stdin")
  .with_output("stdout")
  .with_prompt("test> ")

let rl = @readline.createInterface(options)

rl.on_line(fn(input) {
  println("Received: \{input}")
  rl.prompt()
})

rl.question("What is your name? ", fn(name) {
  println("Hello \{name}!")
  rl.close()
})
```

## Error Handling

### Sync Interface
```moonbit
let rl = @readline.createInterface()

rl.on_close(fn() {
  println("Interface closed")
})

// Handle errors in callbacks
rl.question("Input: ", fn(answer) {
  try {
    process_input(answer)
  } catch {
    err => println("Error: \{err}")
  }
})
```

### Async Interface
```moonbit
async fn safe_input() -> Unit raise {
  let rl = await @readline.createAsyncInterface()
  defer rl.close()
  
  try {
    let input = await rl.question("Enter data: ")
    process_input(input)
  } catch {
    err => println("Failed to process input: \{err}")
  }
}
```

## Performance Notes

- The library uses GNU readline for optimal terminal handling
- History is stored in memory and persists during the session
- Completion functions are called synchronously - keep them fast
- Event listeners are called in the order they were registered
- The async interface polls for input availability every 10ms by default

## Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all examples work correctly
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Dependencies

- GNU readline library (libreadline)
- MoonBit async runtime
- POSIX-compatible operating system

## Troubleshooting

### Common Issues

1. **"Failed to initialize readline"**
   - Ensure libreadline is installed
   - Check that the library is in your system's library path

2. **Completion not working**
   - Verify your completion function returns the correct format
   - Check that tab completion is enabled in your terminal

3. **Async functions hanging**
   - Ensure you're running inside `@async.with_event_loop`
   - Check that you're properly closing interfaces with `defer`

4. **Signal handling not working**
   - Verify your terminal supports signal forwarding
   - Check that signal handlers are properly registered

### Debug Mode

Enable debug output by setting the debug flag (if implemented):

```moonbit
// Debug mode (implementation-specific)
let rl = @readline.createInterface(
  InterfaceOptions::new().with_debug(true)
)
```

For more examples and advanced usage, see the `examples/` directory in the repository.