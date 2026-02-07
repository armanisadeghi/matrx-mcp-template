import uuid
from datetime import datetime, timezone


def register(mcp):
    """Register all virtual table management tools with the MCP server."""

    @mcp.tool()
    def create_virtual_table(table_name: str, columns: list[dict]) -> dict:
        """Create a new virtual table definition.

        Args:
            table_name: The name of the virtual table to create.
            columns: A list of dicts with "name" and "type" keys defining the table schema.
                     Example: [{"name": "title", "type": "text"}, {"name": "count", "type": "integer"}]

        Returns:
            The created table definition including its ID, name, columns, and creation timestamp.
        """
        # TODO: Replace with actual Supabase query:
        #   supabase.table("virtual_table_definitions").insert({
        #       "user_id": current_user_id,
        #       "table_name": table_name,
        #       "columns": columns,
        #   }).execute()

        table_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        return {
            "success": True,
            "table": {
                "id": table_id,
                "table_name": table_name,
                "columns": columns,
                "created_at": now,
                "updated_at": now,
            },
            "message": f"Virtual table '{table_name}' created with {len(columns)} column(s).",
        }

    @mcp.tool()
    def list_virtual_tables() -> dict:
        """List all virtual tables belonging to the current user.

        Returns:
            A dict containing a list of table names and their column definitions.
        """
        # TODO: Replace with actual Supabase query:
        #   supabase.table("virtual_table_definitions")
        #       .select("id, table_name, columns, created_at")
        #       .eq("user_id", current_user_id)
        #       .execute()

        # Placeholder demo data
        return {
            "success": True,
            "tables": [
                {
                    "id": "demo-table-001",
                    "table_name": "contacts",
                    "columns": [
                        {"name": "name", "type": "text"},
                        {"name": "email", "type": "text"},
                        {"name": "phone", "type": "text"},
                    ],
                    "created_at": "2025-01-15T10:00:00+00:00",
                },
                {
                    "id": "demo-table-002",
                    "table_name": "inventory",
                    "columns": [
                        {"name": "item", "type": "text"},
                        {"name": "quantity", "type": "integer"},
                        {"name": "price", "type": "float"},
                    ],
                    "created_at": "2025-01-16T12:30:00+00:00",
                },
            ],
            "count": 2,
        }

    @mcp.tool()
    def get_table_schema(table_name: str) -> dict:
        """Get the column schema for a specific virtual table.

        Args:
            table_name: The name of the virtual table to describe.

        Returns:
            The table schema including column names and types.
        """
        # TODO: Replace with actual Supabase query:
        #   supabase.table("virtual_table_definitions")
        #       .select("id, table_name, columns, created_at, updated_at")
        #       .eq("user_id", current_user_id)
        #       .eq("table_name", table_name)
        #       .single()
        #       .execute()

        # Placeholder demo data
        return {
            "success": True,
            "table_name": table_name,
            "columns": [
                {"name": "id", "type": "uuid"},
                {"name": "name", "type": "text"},
                {"name": "email", "type": "text"},
                {"name": "phone", "type": "text"},
                {"name": "created_at", "type": "timestamp"},
            ],
            "row_count": 42,
        }

    @mcp.tool()
    def insert_row(table_name: str, data: dict) -> dict:
        """Insert a row into a virtual table.

        Args:
            table_name: The name of the virtual table to insert into.
            data: A dict mapping column names to values.
                  Example: {"name": "Alice", "email": "alice@example.com"}

        Returns:
            The inserted row including its generated ID and timestamps.
        """
        # TODO: Replace with actual Supabase query:
        #   1. Validate data keys against the table's column definitions
        #   2. supabase.table("virtual_table_rows").insert({
        #          "user_id": current_user_id,
        #          "table_def_id": table_definition_id,
        #          "row_data": data,
        #      }).execute()

        row_id = str(uuid.uuid4())
        now = datetime.now(timezone.utc).isoformat()

        return {
            "success": True,
            "row": {
                "id": row_id,
                "table_name": table_name,
                "data": data,
                "created_at": now,
                "updated_at": now,
            },
            "message": f"Row inserted into '{table_name}'.",
        }

    @mcp.tool()
    def query_rows(
        table_name: str,
        filters: dict | None = None,
        limit: int = 50,
        offset: int = 0,
    ) -> dict:
        """Query rows from a virtual table with optional filters.

        Args:
            table_name: The name of the virtual table to query.
            filters: Optional dict of column-name to value filters (equality match).
                     Example: {"status": "active"}
            limit: Maximum number of rows to return (default 50).
            offset: Number of rows to skip for pagination (default 0).

        Returns:
            Paginated query results with rows, total count, limit, and offset.
        """
        # TODO: Replace with actual Supabase query:
        #   query = supabase.table("virtual_table_rows")
        #       .select("id, row_data, created_at, updated_at", count="exact")
        #       .eq("user_id", current_user_id)
        #       .eq("table_def_id", table_definition_id)
        #
        #   if filters:
        #       for col, val in filters.items():
        #           query = query.contains("row_data", {col: val})
        #
        #   query = query.range(offset, offset + limit - 1).execute()

        # Placeholder demo data
        demo_rows = [
            {
                "id": "row-001",
                "data": {"name": "Alice", "email": "alice@example.com", "phone": "555-0101"},
                "created_at": "2025-01-17T09:00:00+00:00",
                "updated_at": "2025-01-17T09:00:00+00:00",
            },
            {
                "id": "row-002",
                "data": {"name": "Bob", "email": "bob@example.com", "phone": "555-0102"},
                "created_at": "2025-01-17T09:05:00+00:00",
                "updated_at": "2025-01-17T09:05:00+00:00",
            },
        ]

        return {
            "success": True,
            "table_name": table_name,
            "rows": demo_rows,
            "total_count": 2,
            "limit": limit,
            "offset": offset,
            "filters_applied": filters or {},
        }

    @mcp.tool()
    def update_row(table_name: str, row_id: str, data: dict) -> dict:
        """Update a specific row by ID.

        Args:
            table_name: The name of the virtual table containing the row.
            row_id: The UUID of the row to update.
            data: A dict of column names and their new values.
                  Example: {"email": "newemail@example.com"}

        Returns:
            The updated row with its new data and updated timestamp.
        """
        # TODO: Replace with actual Supabase query:
        #   1. Validate data keys against the table's column definitions
        #   2. supabase.table("virtual_table_rows")
        #          .update({"row_data": merged_data, "updated_at": now})
        #          .eq("id", row_id)
        #          .eq("user_id", current_user_id)
        #          .execute()

        now = datetime.now(timezone.utc).isoformat()

        return {
            "success": True,
            "row": {
                "id": row_id,
                "table_name": table_name,
                "data": data,
                "updated_at": now,
            },
            "message": f"Row '{row_id}' in '{table_name}' updated.",
        }

    @mcp.tool()
    def delete_row(table_name: str, row_id: str) -> dict:
        """Delete a specific row by ID.

        Args:
            table_name: The name of the virtual table containing the row.
            row_id: The UUID of the row to delete.

        Returns:
            Confirmation of the deletion.
        """
        # TODO: Replace with actual Supabase query:
        #   supabase.table("virtual_table_rows")
        #       .delete()
        #       .eq("id", row_id)
        #       .eq("user_id", current_user_id)
        #       .execute()

        return {
            "success": True,
            "deleted": {
                "id": row_id,
                "table_name": table_name,
            },
            "message": f"Row '{row_id}' deleted from '{table_name}'.",
        }

    @mcp.tool()
    def add_column(table_name: str, column_name: str, column_type: str) -> dict:
        """Add a new column to an existing virtual table.

        Args:
            table_name: The name of the virtual table to modify.
            column_name: The name of the new column.
            column_type: The data type of the new column (e.g. "text", "integer", "float", "boolean", "timestamp").

        Returns:
            The updated table schema with the new column included.
        """
        # TODO: Replace with actual Supabase query:
        #   1. Fetch existing column definitions
        #   2. Append the new column
        #   3. supabase.table("virtual_table_definitions")
        #          .update({"columns": updated_columns, "updated_at": now})
        #          .eq("id", table_definition_id)
        #          .eq("user_id", current_user_id)
        #          .execute()

        now = datetime.now(timezone.utc).isoformat()

        return {
            "success": True,
            "table_name": table_name,
            "added_column": {
                "name": column_name,
                "type": column_type,
            },
            "updated_at": now,
            "message": f"Column '{column_name}' ({column_type}) added to '{table_name}'.",
        }
