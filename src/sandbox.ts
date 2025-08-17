import { createManagerFromConfig } from "./database-manager";

const conn = createManagerFromConfig({
    type: "mysql",
    database: process.env.DB_NAME || "dbmcp",
    username: process.env.DB_USER || "dbmcp",
    password: process.env.DB_PASSWORD || "password123",
    host: process.env.DB_HOST || "localhost",
    port: parseInt(process.env.DB_PORT || "3306", 10),
});

await conn.connect();

const dbInfo = await conn.introspect();

for (const table of dbInfo.tables) {
    console.log(`Table: ${table.name}`);
    console.table(table.columns);
    if (table.foreign_keys.length > 0) {
        console.table(table.foreign_keys);
    }
}

process.exit(0);
