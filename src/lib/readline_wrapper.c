#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <unistd.h>
#include <termios.h>
#include <sys/select.h>
#include <sys/ioctl.h>
#include <errno.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <moonbit.h>

// Global state for the readline interface
static struct {
    int initialized;
    char* prompt;
    int paused;
    int closed;
    FILE* input;
    FILE* output;
    char* line_buffer;
    int history_size;
    void (*completion_callback)(void);
    void (*line_callback)(char*);
    void (*close_callback)(void);
    void (*sigint_callback)(void);
    void (*sigtstp_callback)(void);
    void (*sigcont_callback)(void);
} readline_state = {0};

// Signal handlers
static void sigint_handler(int sig) {
    if (readline_state.sigint_callback && !readline_state.paused) {
        readline_state.sigint_callback();
    }
}

static void sigtstp_handler(int sig) {
    if (readline_state.sigtstp_callback) {
        readline_state.sigtstp_callback();
    }
    // Default behavior - suspend the process
    signal(SIGTSTP, SIG_DFL);
    kill(getpid(), SIGTSTP);
}

static void sigcont_handler(int sig) {
    // Restore our signal handler
    signal(SIGTSTP, sigtstp_handler);
    if (readline_state.sigcont_callback) {
        readline_state.sigcont_callback();
    }
}

// Completion generator
static char** completion_generator(const char* text, int start, int end) {
    if (readline_state.completion_callback) {
        readline_state.completion_callback();
    }
    return NULL;
}

// Initialize readline
int mbt_readline_init(void) {
    if (readline_state.initialized) {
        return 1;
    }
    
    readline_state.initialized = 1;
    readline_state.paused = 0;
    readline_state.closed = 0;
    readline_state.input = stdin;
    readline_state.output = stdout;
    readline_state.prompt = strdup("> ");
    readline_state.history_size = 1000;
    
    // Setup completion
    rl_attempted_completion_function = completion_generator;
    
    // Setup signal handlers
    signal(SIGINT, sigint_handler);
    signal(SIGTSTP, sigtstp_handler);
    signal(SIGCONT, sigcont_handler);
    
    // Initialize history
    using_history();
    stifle_history(readline_state.history_size);
    
    return 0;
}

// Cleanup readline
void mbt_readline_cleanup(void) {
    if (!readline_state.initialized) {
        return;
    }
    
    if (readline_state.prompt) {
        free(readline_state.prompt);
        readline_state.prompt = NULL;
    }
    
    if (readline_state.line_buffer) {
        free(readline_state.line_buffer);
        readline_state.line_buffer = NULL;
    }
    
    // Restore default signal handlers
    signal(SIGINT, SIG_DFL);
    signal(SIGTSTP, SIG_DFL);
    signal(SIGCONT, SIG_DFL);
    
    readline_state.initialized = 0;
    readline_state.closed = 1;
}

// Set prompt
void mbt_readline_set_prompt(const char* prompt) {
    if (readline_state.prompt) {
        free(readline_state.prompt);
    }
    readline_state.prompt = strdup(prompt ? prompt : "> ");
}

// Get prompt
const char* mbt_readline_get_prompt(void) {
    return readline_state.prompt ? readline_state.prompt : "> ";
}

// Set input/output streams
void mbt_readline_set_input(FILE* input) {
    readline_state.input = input ? input : stdin;
    rl_instream = readline_state.input;
}

void mbt_readline_set_output(FILE* output) {
    readline_state.output = output ? output : stdout;
    rl_outstream = readline_state.output;
}

// Pause/Resume
void mbt_readline_pause(void) {
    readline_state.paused = 1;
}

void mbt_readline_resume(void) {
    readline_state.paused = 0;
}

int mbt_readline_is_paused(void) {
    return readline_state.paused;
}

// Close interface
void mbt_readline_close(void) {
    if (!readline_state.closed && readline_state.close_callback) {
        readline_state.close_callback();
    }
    readline_state.closed = 1;
    mbt_readline_cleanup();
}

int mbt_readline_is_closed(void) {
    return readline_state.closed;
}

// Write to output
void mbt_readline_write(const char* data) {
    if (readline_state.output && data) {
        fprintf(readline_state.output, "%s", data);
        fflush(readline_state.output);
    }
}

// Read a line (blocking)
char* mbt_readline_read_line(const char* prompt) {
    if (!readline_state.initialized || readline_state.closed || readline_state.paused) {
        return NULL;
    }
    
    const char* use_prompt = prompt ? prompt : readline_state.prompt;
    char* line = readline(use_prompt);
    
    // Handle EOF or interruption
    if (line == NULL) {
        // EOF encountered, set closed state to prevent further reads
        readline_state.closed = 1;
        if (readline_state.close_callback) {
            readline_state.close_callback();
        }
        return NULL;
    }
    
    if (strlen(line) > 0) {
        add_history(line);
    }
    
    return line; // Caller must free this
}

// Non-blocking input check
int mbt_readline_input_available(void) {
    if (!readline_state.initialized || readline_state.closed) {
        return 0;
    }
    
    fd_set readfds;
    struct timeval timeout;
    int fd = fileno(readline_state.input);
    
    FD_ZERO(&readfds);
    FD_SET(fd, &readfds);
    timeout.tv_sec = 0;
    timeout.tv_usec = 0;
    
    return select(fd + 1, &readfds, NULL, NULL, &timeout) > 0;
}

// History management
void mbt_readline_add_history(const char* line) {
    if (line && strlen(line) > 0) {
        add_history(line);
    }
}

void mbt_readline_clear_history(void) {
    clear_history();
}

int mbt_readline_history_length(void) {
    return history_length;
}

char* mbt_readline_get_history(int index) {
    HIST_ENTRY* entry = history_get(index + 1); // readline uses 1-based indexing
    return entry ? strdup(entry->line) : NULL;
}

void mbt_readline_set_history_size(int size) {
    readline_state.history_size = size > 0 ? size : 1000;
    stifle_history(readline_state.history_size);
}

// Callback setters (these will be called from MoonBit)
void mbt_readline_set_line_callback(void (*callback)(char*)) {
    readline_state.line_callback = callback;
}

void mbt_readline_set_close_callback(void (*callback)(void)) {
    readline_state.close_callback = callback;
}

void mbt_readline_set_sigint_callback(void (*callback)(void)) {
    readline_state.sigint_callback = callback;
}

void mbt_readline_set_sigtstp_callback(void (*callback)(void)) {
    readline_state.sigtstp_callback = callback;
}

void mbt_readline_set_sigcont_callback(void (*callback)(void)) {
    readline_state.sigcont_callback = callback;
}

void mbt_readline_set_completion_callback(void (*callback)(void)) {
    readline_state.completion_callback = callback;
}

// Utility function to convert MoonBit string to C string
char* moonbit_string_to_cstr(moonbit_string_t ms) {
    if (!ms) return NULL;
    
    // Get string length by iterating until we find the end or a reasonable limit
    int32_t len = 0;
    while (len < 10000 && ms[len] != 0) { // Safety limit to prevent infinite loop
        len++;
    }
    
    char* cstr = malloc(len + 1);
    if (!cstr) return NULL;
    
    for (int i = 0; i < len; i++) {
        cstr[i] = (char)ms[i]; // Assuming ASCII compatibility
    }
    cstr[len] = '\0';
    
    return cstr;
}

// Utility function to convert C string to MoonBit string
moonbit_string_t cstr_to_moonbit_string(const char* cstr) {
    if (!cstr) {
        return moonbit_make_string(0, 0);
    }
    
    int32_t len = strlen(cstr);
    moonbit_string_t ms = moonbit_make_string(len, 0);
    
    for (int i = 0; i < len; i++) {
        ms[i] = (uint16_t)cstr[i]; // Assuming ASCII compatibility
    }
    
    return ms;
}

// Wrapper for readline that returns MoonBit string
moonbit_string_t mbt_readline_read_line_mbt(moonbit_string_t prompt_ms) {
    char* prompt_cstr = prompt_ms ? moonbit_string_to_cstr(prompt_ms) : NULL;
    char* line = mbt_readline_read_line(prompt_cstr);
    
    if (prompt_cstr) {
        free(prompt_cstr);
    }
    
    if (!line) {
        return NULL; // This will be handled as None in MoonBit
    }
    
    moonbit_string_t result = cstr_to_moonbit_string(line);
    free(line);
    
    return result;
}

// TTY related functions
int mbt_is_tty(int fd) {
    return isatty(fd);
}

int mbt_get_window_size(int* rows, int* cols) {
    struct winsize ws;
    if (ioctl(STDOUT_FILENO, TIOCGWINSZ, &ws) == -1) {
        return -1;
    }
    if (rows) *rows = ws.ws_row;
    if (cols) *cols = ws.ws_col;
    return 0;
}