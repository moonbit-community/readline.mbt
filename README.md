# MoonBit Readline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.0-blue.svg)](https://www.moonbitlang.com/)

A complete Node.js readline-compatible library for MoonBit, providing powerful terminal input capabilities with full async support.

## ✨ Features

- **🔥 100% Node.js readline API compatibility**
- **⚡ Async support** - Complete async/await support
- **🎯 Event-driven architecture** - EventEmitter pattern
- **📝 Advanced line editing** - Based on GNU readline backend
- **📚 History management** - Search and navigation functionality
- **🔍 Tab completion** - Customizable completion functions
- **⚠️ Signal handling** - SIGINT, SIGTSTP, SIGCONT
- **🖥️ Terminal manipulation** - Cursor control, screen clearing
- **🌍 Cross-platform support** - Linux, macOS, Windows

## 🚀 Quick Start

### Installation

Add this library to your MoonBit project:

```bash
moon add allwefantasy/readline.mbt
```

### Basic Usage

```moonbit
fn main {
  let rl = @lib.create_interface_simple()
  
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
  let name = await @lib.questionAsync("What's your name? ")
  println("Hello, \{name}!")
}
```

## 📦 System Requirements

### Recommended: Install readline library

For the best experience, it's recommended to install the GNU readline library:

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

#### Windows (MSYS2)
```bash
pacman -S mingw-w64-x86_64-readline mingw-w64-x86_64-ncurses
```

### 🤖 Automatic Configuration

This library uses intelligent detection scripts to automatically configure the readline library:

- ✅ **When readline library is found**: Full functionality is used
- ⚠️ **When not found**: Automatically uses mock implementation (limited functionality)

### Manual Configuration

If automatic detection fails, you can set environment variables:

```bash
export READLINE_ROOT=/path/to/readline
# or
export READLINE_INCLUDE_PATH=/path/to/readline/include
export READLINE_LIB_PATH=/path/to/readline/lib
```

## 📖 API Reference

### Creating Interfaces

#### `create_interface(options: InterfaceOptions) -> Interface`

Creates a readline interface with specified options.

```moonbit
let options = InterfaceOptions::new()
  .with_input("stdin")
  .with_output("stdout")
  .with_prompt("> ")
  .with_history_size(1000)

let rl = @lib.create_interface(options)
```

#### `create_interface_simple(input~: String?, output~: String?) -> Interface`

Simple interface creation.

```moonbit
let rl = @lib.create_interface_simple(input="stdin", output="stdout")
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

// Interface closed event
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

The async interface provides Promise-based methods:

```moonbit
async fn interactive_session() -> Unit raise {
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  let name = await rl.question("Name: ")
  let age = await rl.question("Age: ")
  
  println("Hello \{name}, age \{age}!")
}
```

### Utility Functions

#### `questionAsync(prompt: String) -> String`

Simple async question (automatically creates and closes interface).

```moonbit
let name = await @lib.questionAsync("Your name: ")
```

#### `confirmAsync(message: String, default~: Bool = false) -> Bool`

Async confirmation dialog.

```moonbit
let confirmed = await @lib.confirmAsync("Continue?", default=true)
```

#### `selectFromMenuAsync(title: String, options: Array[String]) -> Int?`

Async menu selection.

```moonbit
let options = ["Option A", "Option B", "Option C"]
let choice = await @lib.selectFromMenuAsync("Select:", options)
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

let options = InterfaceOptions::new().with_completer(my_completer)
let rl = @lib.create_interface(options)
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

## 💡 Usage Examples

### Interactive Form

```moonbit
async fn user_form() -> Unit raise {
  let rl = await @lib.createAsyncInterface()
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
  
  let confirmed = await @lib.confirmAsync("Is this information correct?")
  
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
  let commands = ["list", "create", "delete", "help", "exit"]
  let rl = @lib.create_interface_simple()
  
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

### Calculator Example

```moonbit
async fn calculator_example() -> Unit raise {
  println("=== Interactive Calculator ===")
  
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  rl.write("Interactive Calculator (type 'quit' to exit)\n")
  rl.write("Enter expressions like: 5 + 3, 10 * 2, etc.\n\n")
  
  while true {
    let input = await rl.question("calc> ")
    
    if input.trim().to_lower() == "quit" {
      rl.write("Goodbye!\n")
      break
    }
    
    match parse_and_calculate(input.trim()) {
      Some(result) => rl.write("Result: \{result}\n")
      None => rl.write("Invalid expression. Try something like '5 + 3'\n")
    }
  }
}

fn parse_and_calculate(expr: String) -> Double? {
  let parts = expr.split(' ')
  if parts.length() != 3 {
    return None
  }
  
  let a = parts[0].parse_double().or_default(0.0)
  let op = parts[1]
  let b = parts[2].parse_double().or_default(0.0)
  
  match op {
    "+" => Some(a + b)
    "-" => Some(a - b)
    "*" => Some(a * b)
    "/" if b != 0.0 => Some(a / b)
    _ => None
  }
}
```

## 🔄 Node.js Compatibility

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

let rl = @lib.create_interface(options)

rl.on_line(fn(input) {
  println("Received: \{input}")
  rl.prompt()
})

rl.question("What is your name? ", fn(name) {
  println("Hello \{name}!")
  rl.close()
})
```

## 🛠️ Error Handling

### Sync Interface
```moonbit
let rl = @lib.create_interface_simple()

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
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  try {
    let input = await rl.question("Enter data: ")
    process_input(input)
  } catch {
    err => println("Failed to process input: \{err}")
  }
}
```

## ⚡ Performance Notes

- The library uses GNU readline for optimal terminal handling
- History is stored in memory and persists during the session
- Completion functions are called synchronously - keep them fast
- Event listeners are called in the order they were registered
- The async interface polls for input availability every 10ms by default

## 🧪 Running Examples

See examples in the `examples/` directory:

```bash
# Basic usage examples
moon run examples/basic_usage.mbt

# Async examples
moon run examples/async_examples.mbt
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all examples work correctly
5. Submit a pull request

## 📜 License

MIT License - see LICENSE file for details.

## 📚 Dependencies

- GNU readline library (libreadline)
- MoonBit async runtime
- POSIX-compatible operating system

## 🔧 Troubleshooting

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

Enable debug output (if implemented):

```moonbit
// Debug mode (implementation-specific)
let options = InterfaceOptions::new().with_debug(true)
let rl = @lib.create_interface(options)
```

For more examples and advanced usage, see the `examples/` directory in the repository.

---

**📞 Need Help?** Please create an issue on GitHub or check the example code.