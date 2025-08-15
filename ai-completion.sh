#!/usr/bin/env bash
# ai-completion.sh – shell-agnostic helper that works in both Bash and Zsh
#
# Source this file from either ~/.bashrc or ~/.zshrc:
#   source /path/to/ai-completion.sh
#
# Requirements:
#   • curl
#   • jq
#   • Environment variable OPENAI_API_KEY must be set.
#
# The function behaves slightly differently depending on whether it is
# running inside Bash or Zsh so that it integrates with the respective
# line-editing facilities and shell history.

ai() {
    local prompt="$*"

    # Detect operating system and shell
    local os_name shell_name
    os_name=$(uname -s)
    if [ -n "$ZSH_VERSION" ]; then
        shell_name="zsh"
    else
        shell_name="bash"
    fi

    # Build JSON payload. Using printf to avoid issues with embedded quotes
    local payload
    payload=$(printf '{
            "model": "gpt-4-turbo",
            "messages": [
                {"role": "system", "content": "You are a %s command generator on %s. Return ONLY the command on a single line without any explanation or markdown formatting."},
                {"role": "user",   "content": "Generate a %s command for: %s"}
            ],
            "temperature": 0.3
        }' "$shell_name" "$os_name" "$shell_name" "$prompt")

    # Fetch response from the OpenAI API
    local response
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "$payload" | jq -r '.choices[0].message.content')

    if [ -n "$ZSH_VERSION" ]; then  # Running in Zsh
        local edited_cmd="$response"
        vared -p "$ " edited_cmd                # inline edit
        print -s -- "$edited_cmd"                # push to history
        eval "$edited_cmd"
    else                             # Assume Bash compatible
        # Use readline for inline edit
        local edited_cmd
        # shellcheck disable=SC2162  # We want to use read -e -i
        read -e -i "$response" -p "$ " edited_cmd
        history -s "$edited_cmd"                # push to history
        eval "$edited_cmd"
    fi
}
