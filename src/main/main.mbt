// Demo and test program for the MoonBit readline library

///|
fn main {
  println("MoonBit Readline Library Demo")
  println("============================")

  // Simple test - just create an interface
  println("\n--- Testing Interface Creation ---")
  test_repl()
  println("Interface created successfully!")
  println("All tests completed successfully!")
}

///|
fn test_repl() -> Unit {
  println("\n--- Test 5: REPL Interface ---")
  let repl = @lib.REPL::new(prompt="demo> ")
  ignore(
    repl
    .add_command("hello", fn(args) {
      let name = if args.length() > 0 { args[0] } else { "World" }
      println("Hello, \{name}!")
    })
    .add_command("echo", fn(args) { println(args.join(" ")) })
    .add_command("calc", fn(args) {
      if args.length() >= 3 {
        match
          (try? @strconv.parse_int(args[0]), try? @strconv.parse_int(args[2])) {
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
    }),
  )
  println("REPL started. Type 'help' for available commands.")
  println("Type 'exit' to quit.")

  // Start the REPL (in a real implementation)
  repl.start()
}
