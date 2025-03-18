gpt() {
    if [[ -z "$1" ]]; then
        echo "❌ Bitte gib eine Frage ein."
        return 1
    fi

    response=$(curl -s https://api.openai.com/v1/chat/completions \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $$OPENAI_API_KEY" \
    -d '{
          "model": "gpt-4",
          "messages": [{"role": "user", "content": "'"${$1}"'"}],
          "max_tokens": 100
        }')

    echo "$response" | jq -r '.choices[0].message.content'
}

fgpt() {
    echo "📝 Frage eingeben:"
    query=$(fzf --prompt "ChatGPT: " --height=10% --border --reverse)

    if [[ -z "$query" ]]; then
        echo "❌ Abgebrochen."
        return 1
    fi


    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $$OPENAI_API_KEY" \
        -d '{
          "model": "gpt-4",
          "messages": [{"role": "user", "content": "'"$query"'"}],
          "max_tokens": 100
        }')

    echo "$response" | jq -r '.choices[0].message.content'
}
