ai-completion
==============

Shell function that lets you draft, edit, and run OpenAI-generated commands directly from your prompt.

A massive simplification of my previous solution: [aicmd](https://github.com/XanderStrike/aicmd)

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

<details>
   <summary>Demo Video:</summary>
   
   https://github.com/user-attachments/assets/93185c1e-ba7b-4935-95a4-3d79eff8cd9c
   
</details>
