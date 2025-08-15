# Basic AI command generator with history support
ai() {
    local prompt="$*"
    local response=$(curl -s https://api.openai.com/v1/chat/completions \
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

    # Put command in readline for editing -- enter will execute and ctrl+c will cancel
    read -e -i "$response" -p "$ " edited_cmd
    history -s "$edited_cmd"  # Add edited version to history
    eval "$edited_cmd"
}
