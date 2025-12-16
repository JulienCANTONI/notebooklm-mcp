/**
 * Global type definitions for NotebookLM MCP Server
 */

/**
 * Source format options for citation display
 */
export type SourceFormat =
  | 'none' // No source extraction (default, fastest)
  | 'inline' // Insert source text inline: "text [1: source excerpt]"
  | 'footnotes' // Append sources at the end as footnotes
  | 'json' // Return sources as separate JSON object
  | 'expanded'; // Replace [1] with full quoted source text

/**
 * Extracted citation data
 */
export interface Citation {
  /** Citation marker (e.g., "[1]", "[2]") */
  marker: string;
  /** Citation number */
  number: number;
  /** Source text from hover tooltip */
  sourceText: string;
  /** Source name/title if available */
  sourceName?: string;
}

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
 * Result from asking a question
 */
export interface AskQuestionResult {
  status: 'success' | 'error';
  question: string;
  answer?: string;
  error?: string;
  notebook_url: string;
  session_id?: string;
  session_info?: {
    age_seconds: number;
    message_count: number;
    last_activity: number;
  };
  /** Extracted source citations (when source_format is not 'none') */
  sources?: {
    /** Format used for extraction */
    format: SourceFormat;
    /** List of extracted citations */
    citations: Citation[];
    /** Whether extraction was successful */
    extraction_success: boolean;
    /** Error message if extraction failed */
    extraction_error?: string;
  };
}

/**
 * Tool call result for MCP (generic wrapper for tool responses)
 */
export interface ToolResult<T = any> {
  success: boolean;
  data?: T;
  error?: string;
}

/**
 * MCP Tool definition
 */
export interface Tool {
  name: string;
  title?: string;
  description: string;
  inputSchema: {
    type: 'object';
    properties: Record<string, any>;
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
 * Global state for the server
 */
export interface ServerState {
  playwright: any;
  sessionManager: any;
  authManager: any;
}
