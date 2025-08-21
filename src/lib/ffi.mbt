// FFI declarations for readline C wrapper

// External types
#extern
type CString

#extern  
type FILE

// Core readline functions
extern "C" fn mbt_readline_init() -> Int = "mbt_readline_init"
extern "C" fn mbt_readline_cleanup() -> Unit = "mbt_readline_cleanup"

// Prompt functions
extern "C" fn mbt_readline_set_prompt(prompt: Bytes) -> Unit = "mbt_readline_set_prompt"
extern "C" fn mbt_readline_get_prompt() -> CString = "mbt_readline_get_prompt"

// Input/Output stream functions
extern "C" fn mbt_readline_set_input(input: FILE) -> Unit = "mbt_readline_set_input"
extern "C" fn mbt_readline_set_output(output: FILE) -> Unit = "mbt_readline_set_output"

// Pause/Resume functions
extern "C" fn mbt_readline_pause() -> Unit = "mbt_readline_pause"
extern "C" fn mbt_readline_resume() -> Unit = "mbt_readline_resume"
extern "C" fn mbt_readline_is_paused() -> Bool = "mbt_readline_is_paused"

// Close functions
extern "C" fn mbt_readline_close() -> Unit = "mbt_readline_close"
extern "C" fn mbt_readline_is_closed() -> Bool = "mbt_readline_is_closed"

// Write function
extern "C" fn mbt_readline_write(data: Bytes) -> Unit = "mbt_readline_write"

// Line reading functions
extern "C" fn mbt_readline_read_line(prompt: Bytes) -> CString = "mbt_readline_read_line"
extern "C" fn mbt_readline_read_line_mbt(prompt: String) -> String = "mbt_readline_read_line_mbt"
extern "C" fn mbt_readline_input_available() -> Bool = "mbt_readline_input_available"

// History functions
extern "C" fn mbt_readline_add_history(line: Bytes) -> Unit = "mbt_readline_add_history"
extern "C" fn mbt_readline_clear_history() -> Unit = "mbt_readline_clear_history"
extern "C" fn mbt_readline_history_length() -> Int = "mbt_readline_history_length"
extern "C" fn mbt_readline_get_history(index: Int) -> CString = "mbt_readline_get_history"
extern "C" fn mbt_readline_set_history_size(size: Int) -> Unit = "mbt_readline_set_history_size"

// Callback setters (using FuncRef for C function pointers)
extern "C" fn mbt_readline_set_line_callback(callback: FuncRef[(Bytes) -> Unit]) -> Unit = "mbt_readline_set_line_callback"
extern "C" fn mbt_readline_set_close_callback(callback: FuncRef[() -> Unit]) -> Unit = "mbt_readline_set_close_callback"
extern "C" fn mbt_readline_set_sigint_callback(callback: FuncRef[() -> Unit]) -> Unit = "mbt_readline_set_sigint_callback"
extern "C" fn mbt_readline_set_sigtstp_callback(callback: FuncRef[() -> Unit]) -> Unit = "mbt_readline_set_sigtstp_callback"
extern "C" fn mbt_readline_set_sigcont_callback(callback: FuncRef[() -> Unit]) -> Unit = "mbt_readline_set_sigcont_callback"
extern "C" fn mbt_readline_set_completion_callback(callback: FuncRef[() -> Unit]) -> Unit = "mbt_readline_set_completion_callback"

// TTY functions
extern "C" fn mbt_is_tty(fd: Int) -> Bool = "mbt_is_tty"
extern "C" fn mbt_get_window_size(rows: Ref[Int], cols: Ref[Int]) -> Int = "mbt_get_window_size"

// CString utility functions
extern "C" fn CString::to_string(self: Self) -> String = "cstr_to_moonbit_string"

// Utility functions
fn string_to_c_bytes(s: String) -> Bytes {
  let mut arr = s.to_bytes().to_array()
  // Ensure null-terminated
  if arr.last() != Some(0) {
    arr.push(0)
  }
  Bytes::from_array(arr)
}

fn bytes_to_string(bytes: Bytes) -> String {
  // Convert bytes to string, removing null terminator if present
  let arr = bytes.to_array()
  let len = if arr.length() > 0 && arr[arr.length() - 1] == 0 {
    arr.length() - 1
  } else {
    arr.length()
  }
  
  let mut result = ""
  for i = 0; i < len; i = i + 1 {
    result = result + Char::from_int(arr[i].to_int()).to_string()
  }
  result
}