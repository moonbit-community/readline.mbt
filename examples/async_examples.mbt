// Async examples using MoonBit readline with async/await

fn main {
  @async.with_event_loop(fn(_) {
    run_async_examples()
  }) catch { err => println("Error: \{err}") }
}

async fn run_async_examples() -> Unit raise {
  // Example 1: Simple async Q&A
  await simple_async_example()
  
  // Example 2: Survey with validation
  await survey_example()
  
  // Example 3: Interactive calculator
  await calculator_example()
  
  // Example 4: Multi-user chat simulation
  await chat_simulation_example()
}

async fn simple_async_example() -> Unit raise {
  println("=== Simple Async Example ===")
  
  let name = await @lib.questionAsync("What's your name? ")
  let age = await @lib.questionAsync("How old are you? ")
  let city = await @lib.questionAsync("Where do you live? ")
  
  println("\nSummary:")
  println("Name: \{name}")
  println("Age: \{age}")
  println("City: \{city}")
}

async fn survey_example() -> Unit raise {
  println("\n=== Survey with Validation ===")
  
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  // Validate email format
  fn is_valid_email(email: String) -> Bool {
    email.contains("@") && email.contains(".")
  }
  
  // Get valid email
  let mut email = ""
  while true {
    email = await rl.question("Enter your email: ")
    if is_valid_email(email) {
      break
    } else {
      rl.write("Invalid email format. Please try again.\n")
    }
  }
  
  // Get valid age
  let mut age = 0
  while true {
    let age_str = await rl.question("Enter your age (18-100): ")
    match age_str.trim().parse_int() {
      Ok(parsed_age) if parsed_age >= 18 && parsed_age <= 100 => {
        age = parsed_age
        break
      }
      _ => {
        rl.write("Please enter a valid age between 18 and 100.\n")
      }
    }
  }
  
  // Rating with menu
  let satisfaction_levels = [
    "Very Dissatisfied",
    "Dissatisfied", 
    "Neutral",
    "Satisfied",
    "Very Satisfied"
  ]
  
  let rating_index = await @lib.selectFromMenuAsync(
    "How satisfied are you with our service?",
    satisfaction_levels
  )
  
  let rating = match rating_index {
    Some(index) => satisfaction_levels[index]
    None => "No rating"
  }
  
  println("\n--- Survey Results ---")
  println("Email: \{email}")
  println("Age: \{age}")
  println("Satisfaction: \{rating}")
}

async fn calculator_example() -> Unit raise {
  println("\n=== Interactive Calculator ===")
  
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

async fn chat_simulation_example() -> Unit raise {
  println("\n=== Chat Simulation ===")
  
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  let username = await rl.question("Enter your username: ")
  rl.write("Welcome to the chat, \{username}!\n")
  rl.write("Type your messages (type '/quit' to exit)\n\n")
  
  // Simulate other users with a background task
  @async.with_task_group(fn(group) {
    group.spawn_bg(fn() {
      simulate_other_users(rl)
    })
    
    // Main chat loop
    while true {
      let message = await rl.question("\{username}: ")
      
      if message.trim() == "/quit" {
        rl.write("You left the chat.\n")
        break
      }
      
      if message.trim().length() > 0 {
        rl.write("[\{get_timestamp()}] \{username}: \{message}\n")
        
        // Simulate message processing
        await process_chat_message(rl, username, message)
      }
    }
  })
}

async fn simulate_other_users(rl: AsyncInterface) -> Unit raise {
  let bot_messages = [
    "Hello everyone!",
    "How's everyone doing?",
    "Nice weather today!",
    "Anyone working on interesting projects?",
    "Time for coffee ☕"
  ]
  
  let bot_names = ["Alice", "Bob", "Charlie"]
  
  for i = 0; i < 5; i = i + 1 {
    await @async.sleep(3000 + i * 2000) // Random delays
    
    if not(rl.closed()) {
      let bot = bot_names[i % bot_names.length()]
      let message = bot_messages[i % bot_messages.length()]
      rl.write("[\{get_timestamp()}] \{bot}: \{message}\n")
    }
  }
}

async fn process_chat_message(rl: AsyncInterface, username: String, message: String) -> Unit raise {
  // Simple bot responses
  if message.to_lower().contains("hello") || message.to_lower().contains("hi") {
    await @async.sleep(1000)
    rl.write("[\{get_timestamp()}] ChatBot: Hello \{username}! 👋\n")
  } else if message.to_lower().contains("time") {
    await @async.sleep(500)
    rl.write("[\{get_timestamp()}] ChatBot: Current time is \{get_timestamp()}\n")
  } else if message.to_lower().contains("help") {
    await @async.sleep(800)
    rl.write("[\{get_timestamp()}] ChatBot: Available commands:\n")
    rl.write("  - Say 'hello' for a greeting\n")
    rl.write("  - Ask about 'time' for current time\n")
    rl.write("  - Type '/quit' to leave\n")
  }
}

fn get_timestamp() -> String {
  // Simplified timestamp - in a real implementation, 
  // you'd use proper date/time functions
  "12:34:56"
}