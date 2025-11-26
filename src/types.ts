/**
 * Global type definitions for NotebookLM MCP Server
 */

import type { SessionManager } from "./session/session-manager.js";
import type { AuthManager } from "./auth/auth-manager.js";
import type { Browser } from "patchright";

/**
 * Session information returned by the API
 */
export interface SessionInfo {
  id: string;
  created_at: number;
  last_activity: number;
  age_seconds: number;
  inactive_seconds: number;
  message_count: number;
  notebook_url: string;
}

/**
 * Subset of session info returned with ask responses
 */
export interface SessionInfoSubset {
  age_seconds: number;
  message_count: number;
  last_activity: number;
}

/**
 * Result from asking a question - discriminated union for type safety
 */
export type AskQuestionResult =
  | {
      status: "success";
      question: string;
      answer: string;
      notebook_url: string;
      session_id: string;
      session_info: SessionInfoSubset;
      error?: never;
    }
  | {
      status: "error";
      question: string;
      error: string;
      notebook_url: string;
      answer?: never;
      session_id?: never;
      session_info?: never;
    };

/**
 * Tool call result for MCP - discriminated union for type safety
 *
 * When success is true, data is guaranteed to be present.
 * When success is false, error is guaranteed to be present.
 * This prevents invalid states like { success: true, error: "..." }
 */
export type ToolResult<T> =
  | { success: true; data: T; error?: never }
  | { success: false; data?: never; error: string };

/**
 * Helper to create a successful ToolResult
 */
export function toolSuccess<T>(data: T): ToolResult<T> {
  return { success: true, data };
}

/**
 * Helper to create a failed ToolResult
 */
export function toolError<T>(error: string): ToolResult<T> {
  return { success: false, error };
}

/**
 * JSON Schema property definition for tool inputs
 */
export interface JSONSchemaProperty {
  type: "string" | "number" | "integer" | "boolean" | "array" | "object";
  description?: string;
  items?: JSONSchemaProperty;
  properties?: Record<string, JSONSchemaProperty>;
  required?: string[];
  enum?: string[];
  default?: unknown;
}

/**
 * MCP Tool definition with proper JSON Schema typing
 */
export interface Tool {
  name: string;
  title?: string;
  description: string;
  inputSchema: {
    type: "object";
    properties: Record<string, JSONSchemaProperty>;
    required?: string[];
  };
}

/**
 * Options for human-like typing
 */
export interface TypingOptions {
  wpm?: number; // Words per minute
  withTypos?: boolean;
}

/**
 * Options for waiting for answers
 */
export interface WaitForAnswerOptions {
  question?: string;
  timeoutMs?: number;
  pollIntervalMs?: number;
  ignoreTexts?: string[];
  debug?: boolean;
}

/**
 * Progress callback function for MCP progress notifications
 */
export type ProgressCallback = (
  message: string,
  progress?: number,
  total?: number
) => Promise<void>;

/**
 * Global state for the server with proper types
 */
export interface ServerState {
  playwright: Browser | null;
  sessionManager: SessionManager;
  authManager: AuthManager;
}
