-- Autonomis Dashboard - Supabase Schema
-- Run this in Supabase SQL Editor

-- Tickets table (tasks/missions)
CREATE TABLE IF NOT EXISTS tickets (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  description TEXT,
  status TEXT NOT NULL DEFAULT 'backlog' CHECK (status IN ('backlog', 'todo', 'in-progress', 'review', 'done')),
  priority TEXT NOT NULL DEFAULT 'medium' CHECK (priority IN ('critical', 'high', 'medium', 'low')),
  assignee TEXT,
  labels TEXT[] DEFAULT '{}',
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Comments table
CREATE TABLE IF NOT EXISTS comments (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  ticket_id TEXT REFERENCES tickets(id) ON DELETE CASCADE,
  author TEXT NOT NULL,
  content TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Messages table (for chat/broadcast)
CREATE TABLE IF NOT EXISTS messages (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  sender TEXT NOT NULL,
  recipient TEXT NOT NULL, -- 'all' for broadcast, agent name for direct
  content TEXT NOT NULL,
  message_type TEXT DEFAULT 'chat' CHECK (message_type IN ('chat', 'broadcast', 'system')),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable realtime for all tables
ALTER PUBLICATION supabase_realtime ADD TABLE tickets;
ALTER PUBLICATION supabase_realtime ADD TABLE comments;
ALTER PUBLICATION supabase_realtime ADD TABLE messages;

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_tickets_status ON tickets(status);
CREATE INDEX IF NOT EXISTS idx_tickets_assignee ON tickets(assignee);
CREATE INDEX IF NOT EXISTS idx_tickets_updated ON tickets(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_comments_ticket ON comments(ticket_id);
CREATE INDEX IF NOT EXISTS idx_messages_recipient ON messages(recipient);
CREATE INDEX IF NOT EXISTS idx_messages_created ON messages(created_at DESC);

-- Sample data (optional - remove if not needed)
INSERT INTO tickets (id, title, description, status, priority, assignee, labels) VALUES
  ('TASK-001', 'Welcome to Autonomis!', 'This is your first task. Edit or delete it.', 'todo', 'medium', 'Agent', ARRAY['onboarding']),
  ('TASK-002', 'Configure your agent', 'Set up SOUL.md and USER.md files', 'backlog', 'high', 'Agent', ARRAY['setup', 'config'])
ON CONFLICT (id) DO NOTHING;
