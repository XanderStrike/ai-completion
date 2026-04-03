ai-completion
==============

Tiny shell helper that lets you draft, tweak, and run AI-generated commands straight from Bash or Zsh.

It exposes two public functions:

- ai  – talks to the OpenAI Chat Completions API
- aio – talks to [apfel](https://github.com/Arthur-Ficial/apfel) (Apple Intelligence) if installed, otherwise falls back to a local Ollama daemon

Quick install
-------------
1. Save the script or clone this repo somewhere.
2. In ~/.bashrc or ~/.zshrc add
   ```shell
   source /path/to/ai-completion.sh
   ```
3. For `ai` export `OPENAI_API_KEY=<your-key>`.

Usage
-----
Describe the task in plain English:

```shell
➜ ai organize all photos in this directory into subfolders using the iso date of the image capture time
$ exiftool '-Directory<DateTimeOriginal' -d '%Y-%m-%d' .

```

The suggestion appears inline on your prompt. Edit if necessary, press ↵, and it executes.

Piping
------
Anything you pipe into the function is forwarded to the model as extra context, e.g.

```shell
➜ git diff --staged | ai write a commit message
$ git commit -am "Refactor payload construction using jq for better JSON handling"
```

Local
-----
Save a buck using a local model for the easy stuff. Local models can be inconsistent, double check all commands.

With [apfel](https://github.com/Arthur-Ficial/apfel) (macOS only, uses Apple Intelligence on-device):

```shell
➜ aio list stopped docker containers
$ docker ps -a --filter status=exited
```


If apfel is not installed, `aio` falls back to Ollama:

```shell
➜ aio list stopped docker containers
Using gemma3:4b on http://localhost:11434...
$ docker ps -a --filter status=exited
```

Environment variables
---------------------
Required for `ai`:
* OPENAI_API_KEY – your OpenAI key

Optional (defaults):
* OPENAI_MODEL  (gpt-5-chat-latest)  
* OPENAI_TEMP   (0.3)          
* OLLAMA_MODEL  (gemma3:4b)    
* OLLAMA_TEMP   (0.3)          
* OLLAMA_HOST   (http://localhost:11434)

Dependencies: curl, jq. Optionally [apfel](https://github.com/Arthur-Ficial/apfel) (`brew install Arthur-Ficial/tap/apfel`) for `aio` on macOS, or a running Ollama daemon as a fallback.
