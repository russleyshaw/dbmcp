import { z } from "zod";

export const ConnectionIdSchema = z.string().uuid();
export type ConnectionId = z.infer<typeof ConnectionIdSchema>;

export const ConnectionConfigSchema = z.object({
    type: z.union([z.literal("postgres"), z.literal("mysql")]),
    host: z.string().default("localhost"),
    port: z.number().int().positive(),
    database: z.string(),
    username: z.string(),
    password: z.string(),
});

export type ConnectionConfig = z.infer<typeof ConnectionConfigSchema>;

export const SqlParamSchema = z.union([z.string(), z.number(), z.boolean(), z.null()]);
export type SqlParam = z.infer<typeof SqlParamSchema>;

export const SqlQuerySchema = z.object({
    sql: z.string().min(1, "Query cannot be empty"),
    params: z.array(SqlParamSchema).optional(),
});
export type SqlQuery = z.infer<typeof SqlQuerySchema>;

export const ColumnSchema = z.object({
    name: z.string(),
    type: z.string(),
    nullable: z.boolean(),
    default_value: z.string().nullable(),
    primary_key: z.boolean(),
});
export type ColumnSchema = z.infer<typeof ColumnSchema>;

export const ForeignKeySchemaSchema = z.object({
    column: z.string(),
    foreign_table: z.string(),
    foreign_column: z.string(),
    constraint_name: z.string(),
});
export type ForeignKeySchema = z.infer<typeof ForeignKeySchemaSchema>;

export const TableSchemaSchema = z.object({
    name: z.string(),
    columns: z.array(ColumnSchema),
    foreign_keys: z.array(ForeignKeySchemaSchema),
});
export type TableSchema = z.infer<typeof TableSchemaSchema>;
export const DatabaseLayoutSchema = z.object({
    name: z.string(),
    tables: z.array(TableSchemaSchema),
});
export type DatabaseLayout = z.infer<typeof DatabaseLayoutSchema>;

export const GetDatabaseInfoArgsSchema = z.object({
    connectionId: ConnectionIdSchema,
});
export type GetDatabaseInfoArgs = z.infer<typeof GetDatabaseInfoArgsSchema>;

export const ExplainQuerySchema = z.object({
    sql: z.string().min(1, "Query cannot be empty"),
    params: z.array(SqlParamSchema).optional(),
    analyze: z
        .boolean()
        .default(false)
        .describe("Include actual execution statistics (slower but more detailed)"),
});
export type ExplainQuery = z.infer<typeof ExplainQuerySchema>;
