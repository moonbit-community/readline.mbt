// Demo and test program for the MoonBit readline library

fn main {
  println("MoonBit Readline Library Demo")
  println("============================")
  
  // Test 1: Simple question
  test_simple_question()
  
  // Test 2: Multiple questions
  test_multiple_questions()
  
  // Test 3: Menu selection
  test_menu_selection()
  
  // Test 4: Confirm dialog
  test_confirm_dialog()
  
  // Test 5: REPL interface
  test_repl()
  
  // Test 6: Async interface
  @async.with_event_loop(fn(_) {
    test_async_interface()
  }) catch { _ => () }
}

fn test_simple_question() -> Unit {
  println("\n--- Test 1: Simple Question ---")
  
  @lib.question("What's your name? ", fn(name) {
    println("Hello, \{name}!")
  })
}

fn test_multiple_questions() -> Unit {
  println("\n--- Test 2: Multiple Questions ---")
  
  let rl = @lib.createInterface()
  
  rl.question("Enter your first name: ", fn(first) {
    rl.question("Enter your last name: ", fn(last) {
      rl.question("Enter your age: ", fn(age) {
        println("Full name: \{first} \{last}, Age: \{age}")
        rl.close()
      })
    })
  })
}

fn test_menu_selection() -> Unit {
  println("\n--- Test 3: Menu Selection ---")
  
  let options = ["Option A", "Option B", "Option C", "Exit"]
  
  @lib.selectFromMenu("Please select an option:", options, fn(selection) {
    match selection {
      Some(index) => println("You selected: \{options[index]}")
      None => println("Invalid selection")
    }
  })
}

fn test_confirm_dialog() -> Unit {
  println("\n--- Test 4: Confirm Dialog ---")
  
  @lib.confirm("Do you want to continue?", fn(confirmed) {
    if confirmed {
      println("Continuing...")
    } else {
      println("Cancelled.")
    }
  })
}

fn test_repl() -> Unit {
  println("\n--- Test 5: REPL Interface ---")
  
  let repl = @lib.REPL::new("demo> ")
  
  repl
    .add_command("hello", fn(args) {
      let name = if args.length() > 0 { args[0] } else { "World" }
      println("Hello, \{name}!")
    })
    .add_command("echo", fn(args) {
      println(args.join(" "))
    })
    .add_command("calc", fn(args) {
      if args.length() >= 3 {
        match (args[0].parse_int(), args[2].parse_int()) {
          (Ok(a), Ok(b)) => {
            let result = match args[1] {
              "+" => a + b
              "-" => a - b
              "*" => a * b
              "/" if b != 0 => a / b
              _ => {
                println("Invalid operator or division by zero")
                return
              }
            }
            println("Result: \{result}")
          }
          _ => println("Invalid numbers")
        }
      } else {
        println("Usage: calc <num1> <op> <num2>")
      }
    })
    .add_command("exit", fn(_) {
      println("Goodbye!")
      // repl.close() // In a real implementation
    })
    .add_command("help", fn(_) {
      println("Available commands:")
      println("  hello [name] - Say hello")
      println("  echo <text>  - Echo text")
      println("  calc <a> <op> <b> - Calculate")
      println("  exit         - Exit REPL")
      println("  help         - Show this help")
    })
  
  println("REPL started. Type 'help' for available commands.")
  println("Type 'exit' to quit.")
  
  // Start the REPL (in a real implementation)
  // repl.start()
}

async fn test_async_interface() -> Unit raise {
  println("\n--- Test 6: Async Interface ---")
  
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  // Async question
  let name = await rl.question("What's your name? ")
  println("Hello, \{name}!")
  
  // Async confirm
  let confirmed = await @lib.confirmAsync("Do you like MoonBit?")
  if confirmed {
    println("Great! MoonBit is awesome!")
  } else {
    println("That's okay, maybe you'll like it more later.")
  }
  
  // Async menu
  let options = ["Red", "Green", "Blue", "Yellow"]
  match await @lib.selectFromMenuAsync("Choose your favorite color:", options) {
    Some(index) => println("You chose: \{options[index]}")
    None => println("No color selected")
  }
  
  // Multiple lines input
  println("Enter multiple lines (empty line to finish):")
  let lines = await @lib.readMultipleLinesAsync("Line: ")
  println("You entered \{lines.length()} lines:")
  for i, line in lines {
    println("\{i + 1}: \{line}")
  }
}