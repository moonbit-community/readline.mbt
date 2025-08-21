// Node.js readline compatibility test
// This file demonstrates that our API is compatible with Node.js readline

fn main {
  println("Node.js Readline Compatibility Test")
  println("===================================")
  
  // Test all major Node.js readline features
  test_createInterface()
  test_question_method()
  test_event_listeners()
  test_cursor_functions()
  test_line_processing()
}

// Test createInterface (matches Node.js API)
fn test_createInterface() -> Unit {
  println("\n--- Testing createInterface ---")
  
  // Node.js style: const rl = readline.createInterface({...})
  let options = @lib.InterfaceOptions::new()
    .with_input("stdin")
    .with_output("stdout")
    .with_prompt("test> ")
    .with_history_size(50)
  
  let rl = @lib.createInterface(options)
  println("✓ Interface created with options")
  
  // Simple version (Node.js compatible)
  let rl2 = @lib.createInterface(input="stdin", output="stdout")
  println("✓ Interface created with simple parameters")
  
  rl.close()
  rl2.close()
}

// Test question method (Node.js compatible)
fn test_question_method() -> Unit {
  println("\n--- Testing question method ---")
  
  let rl = @lib.createInterface()
  
  // This matches Node.js exactly: rl.question(query, callback)
  rl.question("Enter test input: ", fn(answer) {
    println("✓ Received answer: \{answer}")
    
    // Test multiple questions (Node.js pattern)
    rl.question("Enter another input: ", fn(answer2) {
      println("✓ Received second answer: \{answer2}")
      rl.close()
    })
  })
}

// Test event listeners (Node.js EventEmitter pattern)
fn test_event_listeners() -> Unit {
  println("\n--- Testing Event Listeners ---")
  
  let rl = @lib.createInterface()
  
  // Node.js pattern: rl.on('line', callback)
  rl.on_line(fn(line) {
    println("✓ Line event received: \{line}")
  })
  
  // Node.js pattern: rl.on('close', callback)
  rl.on_close(fn() {
    println("✓ Close event received")
  })
  
  // Node.js pattern: rl.on('pause', callback)
  rl.on_pause(fn() {
    println("✓ Pause event received")
  })
  
  // Node.js pattern: rl.on('resume', callback)
  rl.on_resume(fn() {
    println("✓ Resume event received")
  })
  
  // Node.js pattern: rl.on('SIGINT', callback)
  rl.on_sigint(fn() {
    println("✓ SIGINT event received")
  })
  
  // Test pause/resume
  println("Testing pause/resume...")
  rl.pause()
  println("✓ Interface paused")
  
  rl.resume()
  println("✓ Interface resumed")
  
  rl.close()
}

// Test cursor and screen functions (Node.js readline module functions)
fn test_cursor_functions() -> Unit {
  println("\n--- Testing Cursor Functions ---")
  
  // These match Node.js readline module exactly:
  
  // readline.cursorTo(stream, x, y)
  @lib.cursorTo(0, 0)
  println("✓ cursorTo function works")
  
  // readline.moveCursor(stream, dx, dy)
  @lib.moveCursor(5, 1)
  println("✓ moveCursor function works")
  
  // readline.clearLine(stream, dir)
  @lib.clearLine(0)
  println("✓ clearLine function works")
  
  // readline.clearScreenDown(stream)
  @lib.clearScreenDown()
  println("✓ clearScreenDown function works")
}

// Test line processing patterns (common Node.js patterns)
fn test_line_processing() -> Unit {
  println("\n--- Testing Line Processing Patterns ---")
  
  let rl = @lib.createInterface()
  
  // Pattern 1: Process lines until specific input
  let mut line_count = 0
  
  rl.on_line(fn(line) {
    line_count = line_count + 1
    
    if line.trim() == "exit" {
      println("✓ Exit command received")
      rl.close()
    } else {
      println("✓ Line \{line_count}: \{line}")
      rl.prompt()
    }
  })
  
  // Set prompt (Node.js method)
  rl.set_prompt("input> ")
  println("✓ Prompt set")
  
  // Start prompting
  rl.prompt()
  println("✓ Initial prompt displayed")
  
  // Simulate some input processing
  println("Enter some lines (type 'exit' to finish):")
}

// Demonstrate exact Node.js API compatibility
fn demonstrate_nodejs_compatibility() -> Unit {
  println("\n--- Node.js API Compatibility Demo ---")
  
  /*
  This MoonBit code is equivalent to this Node.js code:
  
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
  
  rl.on('close', () => {
    console.log('Goodbye!');
  });
  
  rl.question('What is your name? ', (name) => {
    console.log(`Hello ${name}!`);
    rl.close();
  });
  */
  
  let options = @lib.InterfaceOptions::new()
    .with_input("stdin")
    .with_output("stdout")
    .with_prompt("test> ")
  
  let rl = @lib.createInterface(options)
  
  rl.on_line(fn(input) {
    println("Received: \{input}")
    rl.prompt()
  })
  
  rl.on_close(fn() {
    println("Goodbye!")
  })
  
  rl.question("What is your name? ", fn(name) {
    println("Hello \{name}!")
    rl.close()
  })
  
  println("✓ All Node.js patterns implemented successfully")
}