/**
 * Structured JSON logging for MCP servers.
 */

export type LogLevel = "DEBUG" | "INFO" | "WARN" | "ERROR";

interface LogEntry {
  timestamp: string;
  level: LogLevel;
  logger: string;
  message: string;
  [key: string]: unknown;
}

const LOG_LEVELS: Record<LogLevel, number> = {
  DEBUG: 0,
  INFO: 1,
  WARN: 2,
  ERROR: 3,
};

export class Logger {
  private name: string;
  private minLevel: number;

  constructor(name: string, level: LogLevel = "INFO") {
    this.name = name;
    this.minLevel = LOG_LEVELS[level];
  }

  private log(level: LogLevel, message: string, extra?: Record<string, unknown>): void {
    if (LOG_LEVELS[level] < this.minLevel) return;

    const entry: LogEntry = {
      timestamp: new Date().toISOString(),
      level,
      logger: this.name,
      message,
      ...extra,
    };

    const output = JSON.stringify(entry);

    if (level === "ERROR") {
      console.error(output);
    } else if (level === "WARN") {
      console.warn(output);
    } else {
      console.log(output);
    }
  }

  debug(message: string, extra?: Record<string, unknown>): void {
    this.log("DEBUG", message, extra);
  }

  info(message: string, extra?: Record<string, unknown>): void {
    this.log("INFO", message, extra);
  }

  warn(message: string, extra?: Record<string, unknown>): void {
    this.log("WARN", message, extra);
  }

  error(message: string, extra?: Record<string, unknown>): void {
    this.log("ERROR", message, extra);
  }
}

export function createLogger(mcpName: string, level?: LogLevel): Logger {
  const envLevel = (process.env.LOG_LEVEL || level || "INFO").toUpperCase() as LogLevel;
  return new Logger(mcpName, envLevel);
}
