import mysql, { type Connection } from "mysql2/promise";
import { Client as PgClient } from "pg";
import {
    type ConnectionConfig,
    ConnectionConfigSchema,
    type DatabaseLayout,
    type SqlQuery,
} from "./schemas.ts";

export interface SqlQueryResult {
    columns: string[];
    rows: (number | string | boolean | null)[][];
    [x: string]: unknown;
}

interface IDatabaseConnection {
    connect(): Promise<void>;

    disconnect(): Promise<void>;
    execute(args: SqlQuery): Promise<SqlQueryResult>;
    introspect(): Promise<DatabaseLayout>;
}

export class MysqlDatabaseManager implements IDatabaseConnection {
    config: ConnectionConfig;

    conn: Connection | null = null;

    constructor(config: ConnectionConfig) {
        if (config.type !== "mysql") throw new Error("Invalid database type");

        this.config = config;
    }

    async connect() {
        // mysql2/promise establishes the connection immediately; a separate connect() call is unnecessary
        // and calling it will throw because the promise-based connection object doesn't expose connect().
        this.conn = await mysql.createConnection({
            host: this.config.host,
            port: this.config.port || 3306,
            database: this.config.database,
            user: this.config.username,
            password: this.config.password,
        });
    }

    async introspect(): Promise<DatabaseLayout> {
        const conn = this.conn;
        if (!conn) throw new Error("Not connected");

        // Get database name
        const [dbResult] = await conn.execute("SELECT DATABASE() as db_name");
        const dbName = (dbResult as { db_name: string }[])[0]?.db_name || this.config.database;

        // Get all tables
        const [tablesResult] = await conn.execute(
            "SELECT TABLE_NAME as table_name FROM information_schema.tables WHERE table_schema = ?",
            [this.config.database],
        );
        const tables = tablesResult as { table_name: string }[];

        const tableSchemas = await Promise.all(
            tables.map(async ({ table_name }) => {
                // Get columns for each table
                const [columnsResult] = await conn.execute(
                    `SELECT 
                        COLUMN_NAME as column_name,
                        DATA_TYPE as data_type,
                        IS_NULLABLE as is_nullable,
                        COLUMN_DEFAULT as column_default,
                        COLUMN_KEY as column_key
                     FROM information_schema.columns 
                     WHERE table_schema = ? AND table_name = ?
                     ORDER BY ordinal_position`,
                    [this.config.database, table_name],
                );
                const columns = (
                    columnsResult as {
                        column_name: string;
                        data_type: string;
                        is_nullable: string;
                        column_default: string | null;
                        column_key: string;
                    }[]
                ).map((col) => ({
                    name: col.column_name,
                    type: col.data_type,
                    nullable: col.is_nullable === "YES",
                    default_value: col.column_default,
                    primary_key: col.column_key === "PRI",
                }));

                // Get foreign keys for each table
                const [fkResult] = await conn.execute(
                    `SELECT 
                        COLUMN_NAME as column_name,
                        REFERENCED_TABLE_NAME as referenced_table_name,
                        REFERENCED_COLUMN_NAME as referenced_column_name,
                        CONSTRAINT_NAME as constraint_name
                     FROM information_schema.key_column_usage 
                     WHERE table_schema = ? AND table_name = ? AND referenced_table_name IS NOT NULL`,
                    [this.config.database, table_name],
                );
                const foreign_keys = (
                    fkResult as {
                        column_name: string;
                        referenced_table_name: string;
                        referenced_column_name: string;
                        constraint_name: string;
                    }[]
                ).map((fk) => ({
                    column: fk.column_name,
                    foreign_table: fk.referenced_table_name,
                    foreign_column: fk.referenced_column_name,
                    constraint_name: fk.constraint_name,
                }));

                return {
                    name: table_name,
                    columns,
                    foreign_keys,
                };
            }),
        );

        return {
            name: dbName,
            tables: tableSchemas,
        };
    }

    async execute(query: SqlQuery): Promise<SqlQueryResult> {
        if (!this.conn) throw new Error("Not connected");

        const [rows, fields] = await this.conn.execute(query.sql, query.params || []);

        // Extract column names from fields
        const columns = (fields as { name: string }[]).map((field) => field.name);

        // Convert rows to the expected format
        const formattedRows = (rows as Record<string, string | number | boolean | null>[]).map(
            (row) => columns.map((col) => row[col] ?? null),
        );

        return {
            columns,
            rows: formattedRows,
        };
    }

    async disconnect() {
        if (!this.conn) return;
        try {
            await this.conn.end();
        } catch (error) {
            console.error("Error disconnecting from MySQL:", error);
        }

        this.conn = null;
    }
}

export class PostgresqlDatabaseManager implements IDatabaseConnection {
    config: ConnectionConfig;
    conn: PgClient | null = null;

    constructor(config: ConnectionConfig) {
        if (config.type !== "postgres") throw new Error("Invalid database type");
        this.config = config;
    }

    async connect() {
        const client = new PgClient({
            host: this.config.host,
            port: this.config.port || 5432,
            database: this.config.database,
            user: this.config.username,
            password: this.config.password,
        });

        await client.connect();
        this.conn = client;
    }

    async introspect(): Promise<DatabaseLayout> {
        const conn = this.conn;
        if (!conn) throw new Error("Not connected");

        // Get database name
        const dbResult = await conn.query("SELECT current_database() as db_name");
        const dbName = dbResult.rows[0]?.db_name || this.config.database;

        // Get all tables
        const tablesResult = await conn.query(
            `SELECT TABLE_NAME 
             FROM information_schema.tables 
             WHERE table_schema = 'public' AND table_type = 'BASE TABLE'`,
        );
        const tables = tablesResult.rows as { TABLE_NAME: string }[];

        const tableSchemas = await Promise.all(
            tables.map(async ({ TABLE_NAME }) => {
                // Get columns for each table
                const columnsResult = await conn.query(
                    `SELECT 
                        c.column_name,
                        c.data_type,
                        c.is_nullable,
                        c.column_default,
                        CASE WHEN pk.column_name IS NOT NULL THEN true ELSE false END as is_primary_key
                     FROM information_schema.columns c
                     LEFT JOIN (
                         SELECT ku.column_name
                         FROM information_schema.table_constraints tc
                         JOIN information_schema.key_column_usage ku
                             ON tc.constraint_name = ku.constraint_name
                             AND tc.table_schema = ku.table_schema
                         WHERE tc.constraint_type = 'PRIMARY KEY'
                             AND tc.table_name = $1
                             AND tc.table_schema = 'public'
                     ) pk ON c.column_name = pk.column_name
                     WHERE c.table_name = $1 AND c.table_schema = 'public'
                     ORDER BY c.ordinal_position`,
                    [TABLE_NAME],
                );
                const columns = columnsResult.rows.map(
                    (col: {
                        column_name: string;
                        data_type: string;
                        is_nullable: string;
                        column_default: string | null;
                        is_primary_key: boolean;
                    }) => ({
                        name: col.column_name,
                        type: col.data_type,
                        nullable: col.is_nullable === "YES",
                        default_value: col.column_default,
                        primary_key: col.is_primary_key,
                    }),
                );

                // Get foreign keys for each table
                const fkResult = await conn.query(
                    `SELECT 
                        kcu.column_name,
                        ccu.table_name AS foreign_table_name,
                        ccu.column_name AS foreign_column_name,
                        tc.constraint_name
                     FROM information_schema.table_constraints AS tc 
                     JOIN information_schema.key_column_usage AS kcu
                         ON tc.constraint_name = kcu.constraint_name
                         AND tc.table_schema = kcu.table_schema
                     JOIN information_schema.constraint_column_usage AS ccu
                         ON ccu.constraint_name = tc.constraint_name
                         AND ccu.table_schema = tc.table_schema
                     WHERE tc.constraint_type = 'FOREIGN KEY'
                         AND tc.table_name = $1
                         AND tc.table_schema = 'public'`,
                    [TABLE_NAME],
                );
                const foreign_keys = fkResult.rows.map(
                    (fk: {
                        column_name: string;
                        foreign_table_name: string;
                        foreign_column_name: string;
                        constraint_name: string;
                    }) => ({
                        column: fk.column_name,
                        foreign_table: fk.foreign_table_name,
                        foreign_column: fk.foreign_column_name,
                        constraint_name: fk.constraint_name,
                    }),
                );

                return {
                    name: TABLE_NAME,
                    columns,
                    foreign_keys,
                };
            }),
        );

        return {
            name: dbName,
            tables: tableSchemas,
        };
    }

    async execute(args: SqlQuery): Promise<SqlQueryResult> {
        const conn = this.conn;
        if (!conn) throw new Error("Not connected");

        const result = await conn.query(args.sql, args.params || []);

        // Extract column names from fields
        const columns = result.fields.map((field) => field.name);

        // Convert rows to the expected format
        const formattedRows = result.rows.map(
            (row: Record<string, string | number | boolean | null>) =>
                columns.map((col) => row[col] ?? null),
        );

        return {
            columns,
            rows: formattedRows,
        };
    }

    async disconnect() {
        if (!this.conn) return;

        try {
            await this.conn.end();
        } catch (error) {
            console.error("Error disconnecting from MySQL:", error);
        }
        this.conn = null;
    }
}

export function createManagerFromConfig(config: ConnectionConfig): AnyDatabaseManager {
    const connOptions = ConnectionConfigSchema.parse(config);
    if (connOptions.type === "mysql") {
        return new MysqlDatabaseManager(connOptions);
    }
    if (connOptions.type === "postgres") {
        return new PostgresqlDatabaseManager(connOptions);
    }

    throw new Error(`Unsupported database type: ${connOptions.type as string}`);
}

export type AnyDatabaseManager = MysqlDatabaseManager | PostgresqlDatabaseManager;

export function formatDatabaseLayout(dbInfo: DatabaseLayout) {
    const tableSchemas = dbInfo.tables.map((table) => {
        const columnDefs = table.columns.map((col) => `  ${col.name}: ${col.type}`).join("\n");
        const foreignKeys = table.foreign_keys
            .map((fk) => `  ${fk.column} -> ${fk.foreign_table}.${fk.foreign_column}`)
            .join("\n");
        return `Table: ${table.name}\nColumns:\n${columnDefs}\nForeign Keys:\n${foreignKeys}`;
    });

    return `Database: ${dbInfo.name}\n\n${tableSchemas.join("\n\n")}`;
}
