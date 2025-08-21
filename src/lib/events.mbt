// Event emitter implementation for readline interface

pub type EventListener[T] (T) -> Unit

pub struct EventEmitter[T] {
  mut listeners : Map[String, Array[EventListener[T]]]
}

impl[T] EventEmitter[T] {
  pub fn new() -> EventEmitter[T] {
    { listeners: Map::new() }
  }

  pub fn on(self: Self, event: String, listener: EventListener[T]) -> Self {
    match self.listeners.get(event) {
      Some(existing) => existing.push(listener)
      None => {
        let new_listeners = [listener]
        self.listeners.set(event, new_listeners)
      }
    }
    self
  }

  pub fn once(self: Self, event: String, listener: EventListener[T]) -> Self {
    let once_listener: EventListener[T] = fn(data) {
      listener(data)
      self.off(event, once_listener)
    }
    self.on(event, once_listener)
  }

  pub fn off(self: Self, event: String, listener: EventListener[T]) -> Self {
    match self.listeners.get(event) {
      Some(listeners) => {
        // Note: Function comparison is not directly available in MoonBit
        // This is a simplified implementation - in practice, we'd use unique IDs
        // For now, just remove all listeners for this event
        self.listeners.remove(event)
      }
      None => ()
    }
    self
  }

  pub fn emit(self: Self, event: String, data: T) -> Bool {
    match self.listeners.get(event) {
      Some(listeners) => {
        for listener in listeners {
          listener(data)
        }
        listeners.length() > 0
      }
      None => false
    }
  }

  pub fn remove_all_listeners(self: Self, event?: String) -> Self {
    match event {
      Some(e) => {
        self.listeners.remove(e)
      }
      None => {
        self.listeners.clear()
      }
    }
    self
  }

  pub fn listener_count(self: Self, event: String) -> Int {
    match self.listeners.get(event) {
      Some(listeners) => listeners.length()
      None => 0
    }
  }

  pub fn event_names(self: Self) -> Array[String] {
    let names = Array::new()
    for (name, _) in self.listeners.iter() {
      names.push(name)
    }
    names
  }
}

// Note: Function comparison is not directly available in MoonBit
// In a full implementation, we would use unique listener IDs

// Specialized event data types for readline

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

pub type ReadlineEventEmitter EventEmitter[ReadlineEvent]

impl ReadlineEventEmitter {
  pub fn new() -> ReadlineEventEmitter {
    EventEmitter::new()
  }

  // Convenience methods for specific events
  pub fn on_line(self: Self, listener: (String) -> Unit) -> Self {
    self.on("line", fn(event) {
      match event {
        Line(data) => listener(data)
        _ => ()
      }
    })
  }

  pub fn on_close(self: Self, listener: () -> Unit) -> Self {
    self.on("close", fn(event) {
      match event {
        Close => listener()
        _ => ()
      }
    })
  }

  pub fn on_pause(self: Self, listener: () -> Unit) -> Self {
    self.on("pause", fn(event) {
      match event {
        Pause => listener()
        _ => ()
      }
    })
  }

  pub fn on_resume(self: Self, listener: () -> Unit) -> Self {
    self.on("resume", fn(event) {
      match event {
        Resume => listener()
        _ => ()
      }
    })
  }

  pub fn on_sigint(self: Self, listener: () -> Unit) -> Self {
    self.on("SIGINT", fn(event) {
      match event {
        SIGINT => listener()
        _ => ()
      }
    })
  }

  pub fn on_sigtstp(self: Self, listener: () -> Unit) -> Self {
    self.on("SIGTSTP", fn(event) {
      match event {
        SIGTSTP => listener()
        _ => ()
      }
    })
  }

  pub fn on_sigcont(self: Self, listener: () -> Unit) -> Self {
    self.on("SIGCONT", fn(event) {
      match event {
        SIGCONT => listener()
        _ => ()
      }
    })
  }

  pub fn emit_line(self: Self, line: String) -> Bool {
    self.emit("line", Line(line))
  }

  pub fn emit_close(self: Self) -> Bool {
    self.emit("close", Close)
  }

  pub fn emit_pause(self: Self) -> Bool {
    self.emit("pause", Pause)
  }

  pub fn emit_resume(self: Self) -> Bool {
    self.emit("resume", Resume)
  }

  pub fn emit_sigint(self: Self) -> Bool {
    self.emit("SIGINT", SIGINT)
  }

  pub fn emit_sigtstp(self: Self) -> Bool {
    self.emit("SIGTSTP", SIGTSTP)
  }

  pub fn emit_sigcont(self: Self) -> Bool {
    self.emit("SIGCONT", SIGCONT)
  }
}