{
  "mcpServers": {
    "neal-todos": {
      "type": "http",
      "url": "http://kewtie:3737/mcp/{{ op://Private/to-do-mcp/token }}"
    }
  },
  "permissions": {
    "allow": [
      "mcp__claude_ai_neal_todo__*",
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
      "Bash(docker build*)",
      "Bash(docker images*)",
      "Bash(docker history*)",
      "Bash(docker compose ps*)",
      "Bash(docker compose logs*)",
      "Bash(docker compose build*)",
      "Bash(podman ps*)",
      "Bash(podman logs*)",
      "Bash(podman exec*)",
      "Bash(podman inspect*)",
      "Bash(podman build*)",
      "Bash(podman images*)",
      "Bash(podman history*)",
      "Bash(podman compose ps*)",
      "Bash(podman compose logs*)",
      "Bash(podman compose build*)",
      "Bash(sqlite3 -readonly *)",
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
