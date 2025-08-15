ai-completion
==============

Shell function that lets you draft, edit, and run OpenAI-generated commands directly from your prompt.

Quick install
-------------
1. Save the script or clone this repo somewhere
2. Source it from your shell startup file (Bash or Zsh):
   ```shell
   echo 'source /path/to/ai-completion.sh' >> ~/.bashrc   # or ~/.zshrc
   ```
3. Ensure the OPENAI_API_KEY environment variable is set

Usage
-----
At the prompt type `ai` followed by what you want to do.

```shell
$ ai count files larger than 1 MB in this folder
# <command appears, you can edit it, then it is executed>
```

Requirements: `curl`, `jq`, and the `OPENAI_API_KEY` environment variable.