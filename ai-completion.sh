#!/usr/bin/env bash
# ai-completion.sh – shell-agnostic helper that works in both Bash and Zsh.
# It now supports two back-ends:
#   • ai  – OpenAI Chat Completions API (requires OPENAI_API_KEY)
#   • aio – Local Ollama instance          (requires a running ollama daemon)
#
# Source this file from either ~/.bashrc or ~/.zshrc:
#   source /path/to/ai-completion.sh
#
# Shared requirements:
#   • curl
#   • jq
#
# OPTIONAL environment variables
#   OPENAI_MODEL  – defaults to gpt-4-turbo
#   OPENAI_TEMP   – defaults to 0.3
#   OLLAMA_MODEL  – defaults to gemma3:4b
#   OLLAMA_TEMP   – defaults to 0.3
#   OLLAMA_HOST   – defaults to http://localhost:11434
#
# The helper behaves slightly differently inside Bash vs Zsh so that it
# integrates with the respective line-editing facilities and shell history.
# ----------------------------------------------------------------------------

###############################################################################
# INTERNAL UTILITY FUNCTIONS (NOT MEANT TO BE CALLED DIRECTLY)
###############################################################################

# _ai_detect_environment
# ----------------------
# Determines the readable OS name and the invoking shell (bash|zsh).
# Output: two space-separated strings ─ os_name shell_name
_ai_detect_environment() {
    local os_kernel os_name shell_name

    os_kernel=$(uname -s)
    case "$os_kernel" in
        Linux)
            if [ -r /etc/os-release ]; then
                # shellcheck disable=SC1091 # runtime detection
                os_name=$(grep -m1 '^PRETTY_NAME=' /etc/os-release | cut -d= -f2- | tr -d '"')
            fi
            os_name="${os_name:-Linux}"
            ;;
        Darwin)
            os_name="macOS $(sw_vers -productVersion)"
            ;;
        *)
            os_name="$os_kernel" ;; # Fallback to kernel name
    esac

    if [ -n "$ZSH_VERSION" ]; then
        shell_name="zsh"
    else
        shell_name="bash"
    fi

    printf '%s %s' "$os_name" "$shell_name"
}

# _ai_capture_stdin
# -----------------
# Captures piped input (if any) and prints it to stdout.
_ai_capture_stdin() {
    if [ ! -t 0 ]; then   # stdin is *not* a TTY → something was piped in
        cat
    fi
}

# _ai_interactive_execute <suggested_command>
# ------------------------------------------
# Allows the user to edit the suggested command inline and then executes it
# while adding it to the shell history.
_ai_interactive_execute() {
    local suggestion="$1" edited_cmd

    if [ -n "$ZSH_VERSION" ]; then
        edited_cmd="$suggestion"
        vared -p "$ " edited_cmd             # inline edit
        print -s -- "$edited_cmd"            # push to history
    else  # Bash & compatibles
        # shellcheck disable=SC2162  # read -e -i requires ignoring SC2162
        read -e -i "$suggestion" -p "$ " edited_cmd
        history -s "$edited_cmd"            # push to history
    fi

    # Execute the final command
    eval "$edited_cmd"
}

# _ai_fetch_openai <user_content> <shell_name> <os_name>
# -----------------------------------------------------
# Calls the OpenAI chat completions API and echoes the response.
_ai_fetch_openai() {
    local user_content="$1" shell_name="$2" os_name="$3"

    local model="${OPENAI_MODEL:-gpt-4-turbo}"
    local temp="${OPENAI_TEMP:-0.3}"

    # Build JSON with jq so that escaping is handled correctly
    local payload
    payload=$(jq -n \
        --arg model "$model" \
        --arg sys "You are a ${shell_name} command generator on ${os_name}. Return ONLY the command on a single line without any explanation or markdown formatting." \
        --arg usr "$user_content" \
        --argjson temp "$temp" \
        '{model:$model, messages:[{role:"system", content:$sys}, {role:"user", content:$usr}], temperature:$temp}')

    curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer ${OPENAI_API_KEY:?OPENAI_API_KEY not set}" \
        -d "$payload" | jq -r '.choices[0].message.content'
}

# _ai_fetch_ollama <user_content> <shell_name> <os_name>
# ------------------------------------------------------
# Calls the local Ollama chat endpoint and echoes the response.
_ai_fetch_ollama() {
    local user_content="$1" shell_name="$2" os_name="$3"

    local model="${OLLAMA_MODEL:-gemma3:4b}"
    local temp="${OLLAMA_TEMP:-0.3}"
    local host="${OLLAMA_HOST:-http://localhost:11434}"

    # Build payload using printf (easier than jq because Ollama spec is simpler)
    local payload
    payload=$(printf '{"model":"%s","stream":false,"messages":[{"role":"system","content":"You are a %s command generator on %s. Return ONLY the command on a single line without any explanation or markdown formatting."},{"role":"user","content":"%s"}],"temperature":%s}' \
                      "$model" "$shell_name" "$os_name" "$user_content" "$temp")

    # Informative echo so the user knows which model is being used
    echo "Using $model on $host..." >&2

    curl -s "$host/api/chat" -H "Content-Type: application/json" -d "$payload" | jq -r '.message.content'
}

###############################################################################
# PUBLIC FUNCTIONS
###############################################################################

# _ai_main <provider> <prompt...>
# ------------------------------
# Shared driver for both ai (OpenAI) and aio (Ollama).
_ai_main() {
    local provider="$1"; shift
    local prompt="$*"

    # Capture stdin context
    local stdin_data shell_name os_name
    stdin_data=$(_ai_capture_stdin)

    # Detect environment
    read -r os_name shell_name <<< "$(_ai_detect_environment)"

    # Compose user content
    local user_content
    user_content=$(printf 'Generate a %s command for: %s' "$shell_name" "$prompt")
    if [ -n "$stdin_data" ]; then
        user_content="$user_content\n\nContext:\n$stdin_data"
    fi

    # Retrieve suggestion based on provider
    local suggestion
    case "$provider" in
        openai)  suggestion=$(_ai_fetch_openai "$user_content" "$shell_name" "$os_name") ;;
        ollama)  suggestion=$(_ai_fetch_ollama "$user_content" "$shell_name" "$os_name") ;;
        *)       echo "Unknown provider $provider" >&2; return 1 ;;
    esac

    if [ -z "$suggestion" ]; then
        echo "[ai-completion] No response from $provider" >&2
        return 1
    fi

    _ai_interactive_execute "$suggestion"
}

# ai  ------------------------------------------------------------------------
# Uses the OpenAI Chat Completions API
ai()  { _ai_main openai "$@"; }

# aio ------------------------------------------------------------------------
# Uses a local Ollama instance
aio() { _ai_main ollama "$@"; }
