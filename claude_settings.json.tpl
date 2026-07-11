{
  "mcpServers": {
    "neal-todos": {
      "type": "sse",
      "url": "http://kewtie:3737/mcp/{{ op://Private/to-do-mcp/token }}"
    }
  },
  "permissions": {
    "allow": [
      "mcp_claude_ai_neal_todo",
      "WebSearch",
      "WebFetch",
      "Read",
      "Edit",
      "Write",
      "Bash(npm *)",
      "Bash(pnpm *)",
      "Bash(node *)",
      "Bash(uv *)",
      "Bash(brew list*)",
      "Bash(brew info*)",
      "Bash(brew search*)",
      "Bash(docker ps*)",
      "Bash(docker logs*)",
      "Bash(docker exec*)",
      "Bash(docker inspect*)",
      "Bash(docker compose ps*)",
      "Bash(docker compose logs*)",
      "Bash(ls*)",
      "Bash(find *)",
      "Bash(grep *)",
      "Bash(cat *)",
      "Bash(echo *)",
      "Bash(pwd)",
      "Bash(which *)",
      "Bash(env)",
      "Bash(printenv *)",
      "Bash(curl *)",
      "Bash(python3 *)",
      "Bash(jq *)"
    ],
    "deny": [
      "Bash(rm -rf *)",
      "Bash(sudo rm *)",
      "Bash(git push --force*)",
      "Bash(git reset --hard*)",
      "Bash(git clean -f*)",
      "Bash(chmod -R 777 *)"
    ]
  },
  "defaultMode": "plan",
  "includeCoAuthoredBy": false
}
