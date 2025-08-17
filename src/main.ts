import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { LRUCache } from "lru-cache";
import { v4 as uuidv4 } from "uuid";
import {
    type AnyDatabaseManager,
    createManagerFromConfig,
    formatDatabaseLayout,
} from "./database-manager.ts";
import { formatTable } from "./markdown.ts";
import {
    ConnectionConfigSchema,
    ConnectionIdSchema,
    ExplainQuerySchema,
    SqlQuerySchema,
} from "./schemas.ts";

const server = new McpServer({
    name: "dbmcp",
    version: "1.0.0",
});

const connCache = new LRUCache<string, AnyDatabaseManager>({
    max: 100,
    ttl: 1000 * 60 * 5, // 5 minutes
    dispose: (value) => {
        value.disconnect().catch((error) => {
            console.error("Error disconnecting from database:", error);
        });
    },
});

server.registerTool(
    "connect",
    {
        description:
            "Connect to a database. Use the connection information provided in a dbmcp.json file. If one does not exist, prompt to create one. Optionally write this connection information to a temporary file. If you already have a connectionId, you should not need to connect again. You can use the introspect_database tool to get the schema information.",
        inputSchema: {
            config: ConnectionConfigSchema,
        },
        outputSchema: {
            connectionId: ConnectionIdSchema,
        },
    },
    async ({ config }) => {
        const dbManager = createManagerFromConfig(config);
        await dbManager.connect();
        const connectionId = uuidv4();
        connCache.set(connectionId, dbManager);
        return {
            content: [
                {
                    type: "text",
                    text: `Connected to database. Connection ID: ${connectionId}`,
                },
            ],
            structuredContent: {
                connectionId,
            },
        };
    },
);
server.registerTool(
    "inspect_database",
    {
        description:
            "Inspect the database schema. Database schema information includes tables, columns, relationships, constraints, etc. Run this tool to initially to gain insight into the database structure. ",

        inputSchema: {
            connectionId: ConnectionIdSchema,
        },
    },
    async ({ connectionId }) => {
        const dbManager = connCache.get(connectionId);
        if (!dbManager) throw new Error(`No connection found for ID: ${connectionId}`);

        const schema = await dbManager.introspect();
        return {
            content: [
                {
                    type: "text",
                    text: `Database schema for: ${schema.name}\n\n${formatDatabaseLayout(schema)}`,
                },
            ],
            structuredContent: schema,
        };
    },
);
server.registerTool(
    "execute_query",
    {
        description:
            "Execute a SQL query. The query must be a valid SQL string for the variant of the database. Do not execute INSERT, UPDATE, or DELETE queries. Include reasonable LIMIT clauses to avoid large result sets. Format the results as a markdown table for easy viewing. Optimistically perform this action when already connected to a database and have a connectionId.",
        inputSchema: {
            connectionId: ConnectionIdSchema,
            query: SqlQuerySchema,
        },
    },
    async ({ connectionId, query }) => {
        const dbManager = connCache.get(connectionId);
        if (!dbManager) throw new Error(`No connection found for ID: ${connectionId}`);

        const result = await dbManager.execute(query);

        return {
            content: [
                {
                    type: "text",
                    text: [
                        `Query executed successfully. ${result.rows.length} row(s) returned.`,
                        "\n\n",
                        formatTable(result.columns, result.rows),
                    ].join(""),
                },
            ],
            structuredContent: result,
        };
    },
);

server.registerTool(
    "explain_query",
    {
        description:
            "Generate an execution plan for a SQL query using EXPLAIN. This helps analyze query performance, identify bottlenecks, and optimize queries. Use 'analyze: true' for detailed runtime statistics. Perform this action optimistically when already connected to a database and have a connectionId.",
        inputSchema: {
            connectionId: ConnectionIdSchema,
            query: ExplainQuerySchema,
        },
    },
    async ({ connectionId, query }) => {
        const dbManager = connCache.get(connectionId);
        if (!dbManager) throw new Error(`No connection found for ID: ${connectionId}`);

        // Build the EXPLAIN query based on the database type
        let explainQuery: string;
        if (query.analyze) {
            explainQuery = `EXPLAIN ANALYZE ${query.sql}`;
        } else {
            explainQuery = `EXPLAIN ${query.sql}`;
        }

        const result = await dbManager.execute({
            sql: explainQuery,
            params: query.params,
        });

        return {
            content: [
                {
                    type: "text",
                    text: [
                        `Query execution plan${query.analyze ? " (with analysis)" : ""}:`,
                        "\n\n",
                        formatTable(result.columns, result.rows),
                    ].join(""),
                },
            ],
            structuredContent: {
                ...result,
                originalQuery: query.sql,
                withAnalysis: query.analyze,
            },
        };
    },
);

// Start the server
async function main() {
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error("Database MCP server running on stdio");
}

main().catch((error) => {
    console.error("Server error:", error);
    process.exit(1);
});
