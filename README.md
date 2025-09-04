# MoonBit Readline

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![MoonBit](https://img.shields.io/badge/MoonBit-0.1.0-blue.svg)](https://www.moonbitlang.com/)

一个功能完整、与 Node.js readline 兼容的 MoonBit 库，提供强大的终端输入功能，完全支持异步编程。

## ✨ 特性

- **🔥 100% Node.js readline API 兼容**
- **⚡ 异步支持** - 完整的 async/await 支持
- **🎯 事件驱动架构** - EventEmitter 模式
- **📝 高级行编辑** - 基于 GNU readline 后端
- **📚 历史管理** - 搜索和导航功能
- **🔍 Tab 补全** - 可自定义补全函数
- **⚠️ 信号处理** - SIGINT, SIGTSTP, SIGCONT
- **🖥️ 终端操作** - 光标控制、屏幕清理
- **🌍 跨平台支持** - Linux, macOS, Windows

## 🚀 快速开始

### 安装

将此库添加到您的 MoonBit 项目：

```bash
moon add allwefantasy/readline.mbt
```

### 基本用法

```moonbit
fn main {
  let rl = @lib.create_interface_simple()
  
  rl.question("What's your name? ", fn(name) {
    println("Hello, \{name}!")
    rl.close()
  })
}
```

### 异步用法

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

## 📦 系统要求

### 推荐：安装 readline 库

为了获得最佳体验，建议安装 GNU readline 库：

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

### 🤖 自动配置

本库使用智能检测脚本自动配置 readline 库：

- ✅ **找到 readline 库时**：使用完整功能
- ⚠️ **未找到时**：自动使用模拟实现（功能受限）

### 手动配置

如果自动检测失败，可以设置环境变量：

```bash
export READLINE_ROOT=/path/to/readline
# 或者
export READLINE_INCLUDE_PATH=/path/to/readline/include
export READLINE_LIB_PATH=/path/to/readline/lib
```

## 📖 API 参考

### 创建接口

#### `create_interface(options: InterfaceOptions) -> Interface`

使用指定选项创建 readline 接口。

```moonbit
let options = InterfaceOptions::new()
  .with_input("stdin")
  .with_output("stdout")
  .with_prompt("> ")
  .with_history_size(1000)

let rl = @lib.create_interface(options)
```

#### `create_interface_simple(input~: String?, output~: String?) -> Interface`

简单接口创建。

```moonbit
let rl = @lib.create_interface_simple(input="stdin", output="stdout")
```

### 接口方法

#### `question(query: String, callback: (String) -> Unit) -> Unit`

询问问题并获取用户输入。

```moonbit
rl.question("Enter your age: ", fn(age) {
  println("You are \{age} years old")
})
```

#### `prompt(preserve_cursor~: Bool = false) -> Unit`

显示提示符并等待输入。

```moonbit
rl.set_prompt("custom> ")
rl.prompt()
```

#### `write(data: String, key~: String? = None) -> Unit`

向输出流写入数据。

```moonbit
rl.write("Output text\n")
```

#### `pause() -> Self` / `resume() -> Self`

暂停或恢复接口。

```moonbit
rl.pause()   // 暂停输入处理
rl.resume()  // 恢复输入处理
```

#### `close() -> Unit`

关闭接口并清理资源。

```moonbit
rl.close()
```

### 事件处理

接口实现了 EventEmitter 模式，与 Node.js 兼容：

```moonbit
// 行输入事件
rl.on_line(fn(line) {
  println("Input: \{line}")
})

// 接口关闭事件
rl.on_close(fn() {
  println("Goodbye!")
})

// 信号事件
rl.on_sigint(fn() {
  println("Ctrl+C pressed")
})

rl.on_sigtstp(fn() {
  println("Ctrl+Z pressed")
})
```

### 异步接口

异步接口提供基于 Promise 的方法：

```moonbit
async fn interactive_session() -> Unit raise {
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  let name = await rl.question("Name: ")
  let age = await rl.question("Age: ")
  
  println("Hello \{name}, age \{age}!")
}
```

### 实用函数

#### `questionAsync(prompt: String) -> String`

简单的异步问题（自动创建和关闭接口）。

```moonbit
let name = await @lib.questionAsync("Your name: ")
```

#### `confirmAsync(message: String, default~: Bool = false) -> Bool`

异步确认对话框。

```moonbit
let confirmed = await @lib.confirmAsync("Continue?", default=true)
```

#### `selectFromMenuAsync(title: String, options: Array[String]) -> Int?`

异步菜单选择。

```moonbit
let options = ["Option A", "Option B", "Option C"]
let choice = await @lib.selectFromMenuAsync("Select:", options)
```

### 补全功能

创建自定义补全函数：

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

### 历史管理

```moonbit
// 清除历史
rl.clear_history()

// 获取历史长度
let len = mbt_readline_history_length()

// 设置历史大小
let options = InterfaceOptions::new().with_history_size(500)
```

## 💡 使用示例

### 交互式表单

```moonbit
async fn user_form() -> Unit raise {
  let rl = await @lib.createAsyncInterface()
  defer rl.close()
  
  let name = await rl.question("Full name: ")
  let email = await rl.question("Email: ")
  
  // 验证年龄输入
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

### 命令行工具

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

### 计算器示例

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

## 🔄 Node.js 兼容性

此库设计为 Node.js readline 的直接替代品。以下是对比：

### Node.js 代码
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

### MoonBit 代码
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

## 🛠️ 错误处理

### 同步接口
```moonbit
let rl = @lib.create_interface_simple()

rl.on_close(fn() {
  println("Interface closed")
})

// 在回调中处理错误
rl.question("Input: ", fn(answer) {
  try {
    process_input(answer)
  } catch {
    err => println("Error: \{err}")
  }
})
```

### 异步接口
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

## ⚡ 性能说明

- 库使用 GNU readline 进行最佳终端处理
- 历史记录存储在内存中，在会话期间持续存在
- 补全函数同步调用 - 保持其快速执行
- 事件监听器按注册顺序调用
- 异步接口默认每 10ms 轮询一次输入可用性

## 🧪 运行示例

查看 `examples/` 目录中的示例：

```bash
# 基本用法示例
moon run examples/basic_usage.mbt

# 异步示例
moon run examples/async_examples.mbt
```

## 🤝 贡献

1. Fork 此仓库
2. 创建功能分支
3. 为新功能添加测试
4. 确保所有示例正常工作
5. 提交 Pull Request

## 📜 许可证

MIT License - 详情请参见 LICENSE 文件。

## 📚 依赖项

- GNU readline 库 (libreadline)
- MoonBit async 运行时
- POSIX 兼容操作系统

## 🔧 故障排除

### 常见问题

1. **"Failed to initialize readline"**
   - 确保已安装 libreadline
   - 检查库是否在系统库路径中

2. **补全不工作**
   - 验证补全函数返回正确格式
   - 检查终端是否启用了 tab 补全

3. **异步函数挂起**
   - 确保在 `@async.with_event_loop` 内运行
   - 检查是否正确使用 `defer` 关闭接口

4. **信号处理不工作**
   - 验证终端支持信号转发
   - 检查信号处理程序是否正确注册

### 调试模式

启用调试输出（如果实现）：

```moonbit
// 调试模式（特定于实现）
let options = InterfaceOptions::new().with_debug(true)
let rl = @lib.create_interface(options)
```

更多示例和高级用法，请参见仓库中的 `examples/` 目录。

---

**📞 需要帮助？** 请在 GitHub 上创建 issue 或查看示例代码。