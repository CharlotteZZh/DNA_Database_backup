# Strict Project Access Policy

Claude Code is authorized to access ONLY this directory:

/Users/jiaxinzhang/Desktop/Columbia Mailman/DNA_Database2

## Filesystem

- Read ONLY files inside DNA_Database2.
- Create, edit, move, rename, or delete ONLY files inside DNA_Database2.
- Do NOT read, inspect, search, list, or access any file or directory outside DNA_Database2.
- Do NOT access any other directory on the Desktop.
- Do NOT access any other project, repository, folder, or document on the computer.
- Do NOT access the user's home directory except for the DNA_Database2 path specified above.
- Do NOT access Downloads, Documents, Pictures, Movies, Applications, Library, or any other location outside DNA_Database2.
- Do NOT access hidden files or directories outside DNA_Database2.
- Do NOT access ~/.ssh, ~/.aws, ~/.config, credentials, tokens, passwords, keychains, or environment files outside DNA_Database2.

## Remote Access

- Do NOT use SSH.
- Do NOT connect to Insomnia.
- Do NOT connect to any HPC system.
- Do NOT access /insomnia001 or any other remote filesystem.

## GitHub

- The only Git repository Claude Code may interact with is the Git repository inside DNA_Database2.
- Do NOT access any other Git repository.
- You may inspect and modify the local Git repository.
- Do NOT run git push unless I explicitly approve the push.
- Do NOT modify the GitHub remote.
- Do NOT force-push.

## Commands

- Do NOT execute commands whose purpose is to access files outside DNA_Database2.
- Do NOT use commands such as find, ls, cat, grep, rg, sed, awk, python, R, or shell commands against paths outside DNA_Database2.
- If a task requires accessing anything outside DNA_Database2, STOP and ask for explicit permission.

## Absolute Rule

DNA_Database2 is the ONLY filesystem location authorized for this Claude Code session.

If there is any uncertainty about whether a file or directory is inside DNA_Database2, do not access it. Ask first.
