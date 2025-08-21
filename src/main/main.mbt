// Demo and test program for the MoonBit readline library

///|
fn main {
  ignore(test_repl())
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

  // Note: In a real implementation, you would call repl.start() to start interactive mode
  repl.start()
}
