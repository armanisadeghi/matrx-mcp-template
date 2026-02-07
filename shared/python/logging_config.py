"""
Structured JSON logging configuration for MCP servers.
"""

import logging
import json
import sys
from datetime import datetime, timezone


class JSONFormatter(logging.Formatter):
    """Format log records as JSON for structured logging."""

    def format(self, record: logging.LogRecord) -> str:
        log_entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "level": record.levelname,
            "logger": record.name,
            "message": record.getMessage(),
        }

        if record.exc_info and record.exc_info[0]:
            log_entry["exception"] = self.formatException(record.exc_info)

        # Include any extra fields attached to the record
        for key in ("mcp_name", "tool_name", "user_id", "request_id"):
            value = getattr(record, key, None)
            if value:
                log_entry[key] = value

        return json.dumps(log_entry)


def setup_logging(mcp_name: str, level: str = "INFO") -> logging.Logger:
    """
    Configure structured JSON logging for an MCP server.

    Args:
        mcp_name: Name of the MCP server (included in all log entries)
        level: Logging level (DEBUG, INFO, WARNING, ERROR, CRITICAL)

    Returns:
        Configured logger instance.
    """
    logger = logging.getLogger(mcp_name)
    logger.setLevel(getattr(logging, level.upper(), logging.INFO))

    # Clear existing handlers
    logger.handlers.clear()

    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(JSONFormatter())
    logger.addHandler(handler)

    return logger
