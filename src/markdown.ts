export function formatTable(
    headers: string[],
    rows: (string | number | boolean | null)[][],
): string {
    const headerRow = headers.join(" | ");
    const separator = headers.map(() => "---").join(" | ");
    const dataRows = rows.map((row) => row.map((cell) => cell?.toString() || "NULL").join(" | "));

    return [headerRow, separator, ...dataRows].join("\n");
}
