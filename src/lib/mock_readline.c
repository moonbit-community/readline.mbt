// Mock readline implementation for testing when readline is not available
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <moonbit.h>

// Simple mock implementation without actual readline features
static int mock_initialized = 0;
static char* mock_prompt = NULL;

int mbt_readline_init(void) {
    if (mock_initialized) return 1;
    mock_initialized = 1;
    mock_prompt = strdup("> ");
    return 0;
}

void mbt_readline_cleanup(void) {
    if (mock_prompt) {
        free(mock_prompt);
        mock_prompt = NULL;
    }
    mock_initialized = 0;
}

void mbt_readline_add_history(const char* line) {
    // Mock implementation - just ignore
    (void)line;
}

moonbit_string_t mbt_readline_read_line_mbt(moonbit_string_t prompt_ms) {
    // Mock implementation - return a simple test string
    return moonbit_make_string(11, 0);  // Will create empty string for now
}

// Helper to convert C string to MoonBit string
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