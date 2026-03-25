# n8n Deployment & Workflows

This repository contains infrastructure as code for deploying n8n using Docker and version-controlled workflows for a Telegram bot that creates LinkedIn posts using multiple AI agents.

## Prerequisites

- Docker and Docker Compose installed
- Git for version control
- Telegram Bot Token (from @BotFather)
- OpenAI API Key
- LinkedIn OAuth credentials

## Setup

1. Clone this repository:
   ```bash
   git clone <repository-url>
   cd n8n
   ```

2. Copy the `.env` file and update the values:
   ```bash
   cp .env .env.local
   # Edit .env.local with your secure values
   ```

3. Run the initialization script:
   ```bash
   ./init.sh
   ```

4. Access n8n at http://localhost:5678

5. OpenRouter (optional) and model selection:
   - In n8n OpenAI credential, set API URL to `https://api.openrouter.ai/v1` and API key to your OpenRouter key
   - Use model `gpt-4o-mini` for chat planning/writing/review tasks
   - Use model `gpt-image-1` for image generation

6. Update workflow IDs:
   - After importing all workflows, note their IDs from the URL
   - Update the `workflowId` fields in the main workflow's executeWorkflow nodes to match the actual IDs of the agent workflows

## Workflows

### Main Workflow: `telegram-ai-content-creator.json`
- **Trigger**: Telegram messages
- **Function**: Collects user input until "proceed" is sent
- **Agents**: Orchestrates planner, writer, reviewer, and image agents
- **Output**: Creates LinkedIn post with optional image

### Agent Workflows:
- **`planner-agent.json`**: Analyzes user input and creates content strategy
- **`writer-agent.json`**: Writes engaging LinkedIn post content
- **`reviewer-agent.json`**: Reviews and polishes the content
- **`image-agent.json`**: Handles image analysis and recommendations

## Environment Variables

Update the `.env` file with your values:

- `N8N_BASIC_AUTH_USER`: Admin username
- `N8N_BASIC_AUTH_PASSWORD`: Admin password
- `DB_POSTGRESDB_PASSWORD`: PostgreSQL password
- `N8N_ENCRYPTION_KEY`: Random encryption key for sensitive data

## Credentials Setup in n8n

1. **Telegram**: Create a bot with @BotFather and get the token
2. **OpenAI**: Get your API key from OpenAI
3. **LinkedIn**: Set up OAuth app for posting permissions

## Usage

1. Start a conversation with your Telegram bot
2. Send your ideas, research topics, or content concepts
3. Send images if you want them analyzed or included
4. Send "proceed" when ready
5. The bot will process your input through multiple AI agents
6. A LinkedIn post will be automatically created

## Database Schema

The `schema.sql` file creates tables for:
- `conversation_history`: Stores chat messages
- `user_sessions`: Manages user sessions
- `workflow_logs`: Logs agent executions

## Stopping the Services

```bash
docker-compose down
```

## GitHub Actions deployment

This repository includes a deploy workflow for Linux VPS deployment:

- `.github/workflows/deploy.yml`: runs on `push` to `main`
- `deploy.sh`: optional local/CI helper script

### Required secrets (GitHub)
- `VPS_HOST` (IP or hostname)
- `VPS_USER` (SSH user)
- `VPS_SSH_PRIVATE_KEY` (private key for SSH)

### Server setup reminder
1. Ensure `docker` and `docker-compose` are installed on VPS.
2. Create `/opt/n8n/.env` on VPS with your values.
3. Allow the deploy user to run `docker compose`.

## Volumes

- `n8n_data`: Persistent data for n8n
- `postgres_data`: PostgreSQL database data
