-- Database schema for n8n Telegram bot workflow

-- Conversation History Table
CREATE TABLE IF NOT EXISTS conversation_history (
  id SERIAL PRIMARY KEY,
  chat_id BIGINT,
  user_id BIGINT,
  role VARCHAR(50),
  content TEXT,
  message_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT NOW()
);

-- User Sessions Table
CREATE TABLE IF NOT EXISTS user_sessions (
  id SERIAL PRIMARY KEY,
  user_id BIGINT,
  chat_id BIGINT,
  session_state JSONB,
  last_activity TIMESTAMP,
  created_at TIMESTAMP DEFAULT NOW(),
  UNIQUE(user_id, chat_id)
);

-- Workflow Logs Table
CREATE TABLE IF NOT EXISTS workflow_logs (
  id SERIAL PRIMARY KEY,
  workflow_id VARCHAR(255),
  chat_id BIGINT,
  agent_id VARCHAR(255),
  input JSONB,
  output JSONB,
  duration INTEGER,
  status VARCHAR(50),
  error_message TEXT,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX IF NOT EXISTS idx_conversation_chat_id ON conversation_history(chat_id);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON user_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_logs_chat_id ON workflow_logs(chat_id);