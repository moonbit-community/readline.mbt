// Event emitter implementation for readline interface

///|
pub struct EventListener[T]((T) -> Unit)

///|
pub struct EventEmitter[T] {
  mut listeners : Map[String, Array[EventListener[T]]]
}

///|
fn[T] EventEmitter::new() -> EventEmitter[T] {
  { listeners: Map::new() }
}

///|
fn[T] EventEmitter::on(
  self : EventEmitter[T],
  event : String,
  listener : EventListener[T],
) -> EventEmitter[T] {
  match self.listeners.get(event) {
    Some(existing) => existing.push(listener)
    None => {
      let new_listeners = [listener]
      self.listeners.set(event, new_listeners)
    }
  }
  self
}

///|
fn[T] EventEmitter::once(
  self : EventEmitter[T],
  event : String,
  listener : EventListener[T],
) -> EventEmitter[T] {
  // For simplicity, we'll just add it as a regular listener
  // In a real implementation, we'd need unique IDs for listeners
  self.on(event, listener)
}

///|
fn[T] EventEmitter::off(
  self : EventEmitter[T],
  event : String,
  listener : EventListener[T],
) -> EventEmitter[T] {
  match self.listeners.get(event) {
    Some(listeners) =>
      // Note: Function comparison is not directly available in MoonBit
      // This is a simplified implementation - in practice, we'd use unique IDs
      // For now, just remove all listeners for this event
      self.listeners.remove(event) |> ignore
    None => ()
  }
  self
}

///|
fn[T] EventEmitter::emit(
  self : EventEmitter[T],
  event : String,
  data : T,
) -> Bool {
  match self.listeners.get(event) {
    Some(listeners) => {
      for listener in listeners {
        let EventListener(f) = listener
        f(data)
      }
      listeners.length() > 0
    }
    None => false
  }
}

///|
fn[T] EventEmitter::remove_all_listeners(
  self : EventEmitter[T],
  event~ : String?,
) -> EventEmitter[T] {
  match event {
    Some(e) => self.listeners.remove(e) |> ignore
    None => self.listeners.clear()
  }
  self
}

///|
fn[T] EventEmitter::listener_count(
  self : EventEmitter[T],
  event : String,
) -> Int {
  match self.listeners.get(event) {
    Some(listeners) => listeners.length()
    None => 0
  }
}

///|
fn[T] EventEmitter::event_names(self : EventEmitter[T]) -> Array[String] {
  let names = Array::new()
  for entry in self.listeners.iter() {
    let (name, _) = entry
    names.push(name)
  }
  names
}

// Note: Function comparison is not directly available in MoonBit
// In a full implementation, we would use unique listener IDs

// Specialized event data types for readline

///|
pub enum ReadlineEvent {
  Line(String)
  Close
  Pause
  Resume
  SIGINT
  SIGTSTP
  SIGCONT
  History(String)
}

///|
typealias EventEmitter[ReadlineEvent] as ReadlineEventEmitter

///|
fn ReadlineEventEmitter::create() -> ReadlineEventEmitter {
  EventEmitter::new()
}

// Convenience methods for specific events

///|
fn ReadlineEventEmitter::on_line(
  self : ReadlineEventEmitter,
  listener : (String) -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "line",
    EventListener(fn(event) {
      match event {
        Line(data) => listener(data)
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_close(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "close",
    EventListener(fn(event) {
      match event {
        Close => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_pause(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "pause",
    EventListener(fn(event) {
      match event {
        Pause => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_resume(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "resume",
    EventListener(fn(event) {
      match event {
        Resume => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_sigint(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "SIGINT",
    EventListener(fn(event) {
      match event {
        SIGINT => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_sigtstp(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "SIGTSTP",
    EventListener(fn(event) {
      match event {
        SIGTSTP => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::on_sigcont(
  self : ReadlineEventEmitter,
  listener : () -> Unit,
) -> ReadlineEventEmitter {
  self.on(
    "SIGCONT",
    EventListener(fn(event) {
      match event {
        SIGCONT => listener()
        _ => ()
      }
    }),
  )
}

///|
fn ReadlineEventEmitter::emit_line(
  self : ReadlineEventEmitter,
  line : String,
) -> Bool {
  self.emit("line", Line(line))
}

///|
fn ReadlineEventEmitter::emit_close(self : ReadlineEventEmitter) -> Bool {
  self.emit("close", Close)
}

///|
fn ReadlineEventEmitter::emit_pause(self : ReadlineEventEmitter) -> Bool {
  self.emit("pause", Pause)
}

///|
fn ReadlineEventEmitter::emit_resume(self : ReadlineEventEmitter) -> Bool {
  self.emit("resume", Resume)
}

///|
fn ReadlineEventEmitter::emit_sigint(self : ReadlineEventEmitter) -> Bool {
  self.emit("SIGINT", SIGINT)
}

///|
fn ReadlineEventEmitter::emit_sigtstp(self : ReadlineEventEmitter) -> Bool {
  self.emit("SIGTSTP", SIGTSTP)
}

///|
fn ReadlineEventEmitter::emit_sigcont(self : ReadlineEventEmitter) -> Bool {
  self.emit("SIGCONT", SIGCONT)
}
