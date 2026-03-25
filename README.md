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

5. Workflows are imported automatically after `n8n` starts from the `workflows/` directory.
   The import step waits for the first n8n user to exist in Postgres, imports with `--userId`, and then restarts `n8n` once so the UI reloads the updated database state.
   Their top-level IDs are version-controlled so the main workflow can keep stable `Execute Workflow` references.

6. OpenRouter (optional) and model selection:
   - In n8n OpenAI credential, set API URL to `https://api.openrouter.ai/v1` and API key to your OpenRouter key
   - Use model `gpt-4o-mini` for chat planning/writing/review tasks
   - Use model `gpt-image-1` for image generation

7. If you already deployed before this change, restart the `n8n` service once so the workflows are imported into the database.

## Workflows

Workflow JSON files are mounted into the container and imported after startup with `n8n import:workflow --separate`.
If the owner signup flow has not completed yet, the helper skips the import rather than creating owner-less workflows that may not appear in the UI.
Because the files include stable top-level workflow IDs, repeat deploys keep the cross-workflow references intact.

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
2. **OpenRouter** (recommended):
   - Go to n8n Credentials > OpenAI
   - Set **API URL** to `https://api.openrouter.ai/v1`
   - Set **API Key** to your OpenRouter API key
   - Models used:
     - Chat tasks (planner/writer/reviewer): `gpt-4o` or `gpt-4o-mini`
     - Image analysis: `gpt-4-vision` (or compatible model)
     - Image generation: `gpt-image-1` (or equivalent)
3. **LinkedIn**: Set up OAuth app for posting permissions

## LLM Providers

All agents use `n8n-nodes-base.openai` which is OpenAI API-compatible:

| Agent | Model | Purpose |
|-------|-------|---------|
| Planner | gpt-4o-mini | Content strategy analysis |
| Writer | gpt-4o-mini | LinkedIn post creation |
| Reviewer | gpt-4o-mini | Content polish & review |
| Image Analyzer | gpt-4-vision | Image understanding |
| Image Generator | gpt-image-1 | Image creation |

To use **OpenRouter**: Update the OpenAI credential endpoint to `https://api.openrouter.ai/v1` in n8n UI.

## Usage

1. Start a conversation with your Telegram bot
2. Send your ideas, research topics, or content concepts
3. Send images if you want them analyzed or included
4. Send "proceed" when ready
5. The bot will process your input through multiple AI agents
6. A LinkedIn post will be created (default: **saved as draft**)

## Post Modes

By default, posts are **saved as drafts** for manual review before publishing.

To change the behavior, set the `POST_MODE` environment variable:

- `POST_MODE=draft` (default): Saves to database, waits for manual review
- `POST_MODE=public`: Publishes directly to LinkedIn

Update in `.env`:
```
POST_MODE=draft
```

Or set in n8n workflow if needed. Draft posts are stored in the `drafts` table and can be reviewed/published manually.

## Database Schema

The `schema.sql` file creates tables for:
- `conversation_history`: Stores chat messages
- `user_sessions`: Manages user sessions
- `workflow_logs`: Logs agent executions
- `drafts`: Stores LinkedIn post drafts for manual review

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

Deployments now force-recreate the containers, wait for the `n8n` container to accept commands, wait for an n8n owner user, import workflows with explicit user ownership, and restart `n8n` once so the imported workflows appear in the UI.

## Volumes

- `n8n_data`: Persistent data for n8n
- `postgres_data`: PostgreSQL database data
