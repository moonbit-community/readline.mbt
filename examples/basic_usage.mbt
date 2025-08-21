// Basic usage examples for MoonBit readline

fn main {
  // Example 1: Simple question and answer
  simple_question_example()
  
  // Example 2: Interactive form
  interactive_form_example()
  
  // Example 3: Command completion
  command_completion_example()
}

fn simple_question_example() -> Unit {
  println("=== Simple Question Example ===")
  
  let readline = @lib.createInterface()
  
  readline.question("What's your favorite programming language? ", fn(answer) {
    println("Great choice! \{answer} is awesome.")
    readline.close()
  })
}

fn interactive_form_example() -> Unit {
  println("\n=== Interactive Form Example ===")
  
  let readline = @lib.createInterface()
  let mut user_data = Map::new()
  
  fn ask_name() {
    readline.question("Name: ", fn(name) {
      user_data.set("name", name)
      ask_email()
    })
  }
  
  fn ask_email() {
    readline.question("Email: ", fn(email) {
      user_data.set("email", email)
      ask_age()
    })
  }
  
  fn ask_age() {
    readline.question("Age: ", fn(age) {
      user_data.set("age", age)
      show_summary()
    })
  }
  
  fn show_summary() {
    println("\n--- User Information ---")
    println("Name:  \{user_data.get("name").or("")}")
    println("Email: \{user_data.get("email").or("")}")
    println("Age:   \{user_data.get("age").or("")}")
    readline.close()
  }
  
  ask_name()
}

fn command_completion_example() -> Unit {
  println("\n=== Command Completion Example ===")
  
  let commands = ["help", "list", "create", "delete", "update", "exit"]
  let readline = @lib.createInterfaceWithCommands(commands)
  
  println("Available commands: \{commands.join(", ")}")
  println("Type a command (tab completion available):")
  
  readline.on_line(fn(line) {
    let command = line.trim()
    match command {
      "help" => {
        println("Available commands:")
        for cmd in commands {
          println("  \{cmd}")
        }
        readline.prompt()
      }
      "list" => {
        println("Listing items...")
        readline.prompt()
      }
      "create" => {
        println("Creating new item...")
        readline.prompt()
      }
      "delete" => {
        println("Deleting item...")
        readline.prompt()
      }
      "update" => {
        println("Updating item...")
        readline.prompt()
      }
      "exit" => {
        println("Goodbye!")
        readline.close()
      }
      "" => {
        readline.prompt()
      }
      _ => {
        println("Unknown command: \{command}")
        println("Type 'help' for available commands.")
        readline.prompt()
      }
    }
  })
  
  readline.prompt()
}