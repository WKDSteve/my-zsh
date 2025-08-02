# Simple CLI function to query ChatGPT via OpenAI API with a direct string argument
gpt() {
    # Check if the user passed any argument; if not, print error and return
    if [[ -z "$1" ]]; then
        echo "❌ Please provide a question."
        return 1
    fi

    # Join all arguments into a single prompt string
    local prompt="$*"

    # Send a POST request to the OpenAI Chat API using the user's input as the prompt
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $OPENAI_API_KEY" \
        -d '{
            "model": "gpt-4",
            "messages": [{"role": "user", "content": "'"${prompt}"'"}],
            "max_tokens": 100
        }')

    # Parse the response with jq and extract the assistant's reply
    echo "$response" | jq -r '.choices[0].message.content'
}


# Interactive CLI function to select a readable file and ask ChatGPT a question about its contents
fgpt() {
    if [ -z "$OPENAI_API_KEY" ]; then
        echo "❌ OPENAI_API_KEY is not set."
        return 1
    fi

    echo "📄 Select a file (searching...)"

    # Use find to exclude common unwanted folders and unreadable files
    file=$(find . \
        -type d \( -name .git -o -name .venv -o -name node_modules -o -name __pycache__ \) -prune -false \
        -o -type f -readable \
        | fzf --prompt "Choose file: " --height=40% --reverse --border)

    if [ -z "$file" ]; then
        echo "❌ No file selected."
        return 1
    fi

    echo "🧠 Enter your question about the file:"
    printf "Question: "
    IFS= read -r question

    if [ -z "$question" ]; then
        echo "❌ No question entered."
        return 1
    fi

    content=$(cat "$file")

    # Measure character length of file content (in bytes, safe for any shell)
    content_len=$(printf "%s" "$content" | wc -c)
    max_chars=3500

    if [ "$content_len" -gt "$max_chars" ]; then
        # Truncate content safely (by byte length, supports both Bash & Zsh)
        content=$(printf "%s" "$content" | head -c "$max_chars")
        content="${content}..."
    fi

    # Build prompt
    prompt="$question

\`\`\`
$content
\`\`\`"

    # Build JSON payload with jq (safer than quoted strings)
    json=$(jq -n \
      --arg prompt "$prompt" \
      '{
         model: "gpt-4",
         messages: [ { role: "user", content: $prompt } ],
         max_tokens: 400
       }')

    # Send to OpenAI API
    response=$(curl -s https://api.openai.com/v1/chat/completions \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer '"$OPENAI_API_KEY"'" \
        -d "$json")

    # Output response (if available)
    echo "$response" | jq -r '.choices[0].message.content // "❌ No response."'
}

