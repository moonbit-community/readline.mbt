// Async readline interface for use with MoonBit's async runtime

// Note: This is a placeholder implementation since async functionality is not available
// This file exists for future compatibility when MoonBit async features are released

// Placeholder struct for future async interface

///|
pub struct AsyncInterface {
  interface : Interface
}

///|
fn AsyncInterface::new(options : InterfaceOptions) -> AsyncInterface {
  let interface = Interface::new(options)
  AsyncInterface::{ interface, }
}

// Basic delegation methods (synchronous for now)

///|
fn AsyncInterface::write(
  self : AsyncInterface,
  data : String,
  key~ : String? = None,
) -> Unit {
  self.interface.write(data, key~)
}

///|
fn AsyncInterface::close(self : AsyncInterface) -> Unit {
  self.interface.close()
}

///|
fn AsyncInterface::set_prompt(self : AsyncInterface, prompt : String) -> Unit {
  self.interface.set_prompt(prompt)
}

///|
fn AsyncInterface::get_prompt(self : AsyncInterface) -> String {
  self.interface.get_prompt()
}

///|
fn AsyncInterface::closed(self : AsyncInterface) -> Bool {
  self.interface.closed()
}

// Module-level functions for compatibility

///|
pub fn create_async_interface(options : InterfaceOptions) -> AsyncInterface {
  AsyncInterface::new(options)
}

///|
pub fn create_async_interface_simple(
  input~ : String?,
  output~ : String?,
) -> AsyncInterface {
  let options = InterfaceOptions::new()
  let options = match input {
    Some(i) => options.with_input(i)
    None => options
  }
  let options = match output {
    Some(o) => options.with_output(o)
    None => options
  }
  AsyncInterface::new(options)
}
