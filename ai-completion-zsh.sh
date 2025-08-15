ai() {
    local prompt="$*"
    local response
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d "{
            \"model\": \"gpt-4-turbo\",
            \"messages\": [
                {
                    \"role\": \"system\",
                    \"content\": \"You are a bash command generator. Return ONLY the bash command on a single line without any explanation or markdown formatting.\"
                },
                {
                    \"role\": \"user\",
                    \"content\": \"Generate a bash command for: $prompt\"
                }
            ],
            \"temperature\": 0.3
        }" | jq -r '.choices[0].message.content')

    # Interactive edit using zsh's vared
    local edited_cmd="$response"
    vared -p "$ " edited_cmd

    print -s "$edited_cmd"  # Add edited version to history
    eval "$edited_cmd"
}
