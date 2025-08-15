#!/usr/bin/env bash
# ai-completion-ollama.sh – shell-agnostic helper that works in both Bash and Zsh
# identical UX to ai-completion.sh but uses a local Ollama model.
#
# Source this file from either ~/.bashrc or ~/.zshrc:
#   source /path/to/ai-completion-ollama.sh
#
# Requirements:
#   • curl
#   • jq
#   • An Ollama daemon running locally ( https://ollama.ai )
#   • OLLAMA_MODEL env var optional (defaults to gemma3:4b)
#   • OLLAMA_HOST env var optional (defaults to http://localhost:11434/api/chat)
#
# The function behaves slightly differently depending on whether it is
# running inside Bash or Zsh so that it integrates with the respective
# line-editing facilities and shell history.

aio() {
    local prompt="$*"

    # Detect OS and shell so we can prompt the model correctly
    local os_name shell_name
    os_name=$(uname -s)
    if [ -n "$ZSH_VERSION" ]; then
        shell_name="zsh"
    else
        shell_name="bash"
    fi

    # Model can be overridden via env var
    local model="${OLLAMA_MODEL:-gemma3:4b}"

    # Build JSON payload expected by Ollama chat endpoint
    # https://github.com/jmorganca/ollama/blob/main/docs/api.md#chat
    local payload
    payload=$(printf '{
            "model": "%s",
            "stream": false,
            "messages": [
                {"role": "system", "content": "You are a %s command generator on %s. Return ONLY the command on a single line without any explanation or markdown formatting."},
                {"role": "user",   "content": "Generate a %s command for: %s"}
            ],
            "temperature": 0.3
        }' "$model" "$shell_name" "$os_name" "$shell_name" "$prompt")

    # Resolve Ollama host, default to localhost if not set
    local ollama_host="${OLLAMA_HOST:-http://localhost:11434}"

    echo "Using $model on host $ollama_host..."

    # Query local Ollama instance at the specified host
    local response
    response=$(curl -s "${ollama_host}/api/chat" \
        -H "Content-Type: application/json" \
        -d "$payload" | jq -r '.message.content')

    # Fallback if jq/path failed
    if [ -z "$response" ]; then
        echo "[ai-completion] No response from Ollama" >&2
        return 1
    fi

    if [ -n "$ZSH_VERSION" ]; then  # Running in Zsh
        local edited_cmd="$response"
        vared -p "$ " edited_cmd                # inline edit
        print -s -- "$edited_cmd"                # push to history
        eval "$edited_cmd"
    else                             # Assume Bash compatible
        local edited_cmd
        # shellcheck disable=SC2162  # We want to use read -e -i
        read -e -i "$response" -p "$ " edited_cmd
        history -s "$edited_cmd"                # push to history
        eval "$edited_cmd"
    fi
}
