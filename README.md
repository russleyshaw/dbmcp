# Database MCP Server

A Model Context Protocol (MCP) server that provides database connectivity and schema introspection tools for PostgreSQL, MySQL databases.

## Features

- **Multiple Database Support**: Connect to PostgreSQL, MySQL databases
- **Schema Introspection**: Get complete database schemas including tables, columns, indexes, foreign keys, and constraints
- **Query Execution**: Execute SQL queries with parameter support
- **Connection Management**: Connect and disconnect from databases

## Installation

### Option 1: Download Pre-compiled Binary (Recommended)

Download the latest compiled binary for your platform from the [GitHub Releases](https://github.com/russley/db-mcp/releases) page:

### Option 2: Build from Source

```bash
bun install
bun run compile
```

This creates executables in the dist directory.

## Usage

This is an MCP server that should be used with Claude Code or other MCP-compatible clients.

### Available Tools

#### 1. `connect_database`
Connect to a database. Supports environment variable defaults for easier configuration.

**Parameters:**
- `type`: Database type - "postgresql", "mysql"
- `host`: Database host
- `port`: Database port
- `database`: Database name
- `username`: Username
- `password`: Password


#### 2. `get_database_schema`
Get the complete database schema or schema for a specific table.

**Parameters:**
- `connectionId`: ID of the database connection

**Returns:** JSON object containing:
- Database name
- Tables with columns, indexes, and foreign keys
- Column details (name, type, nullable, default, etc.)
- Index information (name, uniqueness, columns)
- Foreign key relationships

#### 3. `execute_query`
Execute a SQL query against the connected database.

**Parameters:**
- `connectionId`: ID of the database connection
- `query`: SQL query to execute
- `parameters`: Array of parameters for parameterized queries

**Returns:** Query results including rows, row count, and field information

## Configuration with Claude Code

Add this to your MCP configuration:

```json
{
  "mcpServers": {
    "dbmcp": {
      "command": "npx",
      "args": ["@russley/dbmcp"],
      "cwd": "."
    }
  }
}
```


## Security Notes

- Be cautious with database credentials
- Consider creating a dedicated database user for the MCP server with limited permissions
- Always include reasonable limits and indexes to improve query performance
- This tool is designed for development and analysis purposes

## Development

### Requirements
- [Bun](https://bun.sh/) runtime
- Node.js/TypeScript (for development)

### Setup
```bash
bun install
```

### Available Scripts
- `bun start` - Run the MCP server
- `bun run compile` - Build executable binary
- `bun run lint` - Lint and format code with Biome
- `bun run mcp:inspect` - Debug MCP server with inspector

