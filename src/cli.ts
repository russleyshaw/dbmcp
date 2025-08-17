#!/usr/bin/env node

import { spawn } from "node:child_process";
import { existsSync } from "node:fs";
import { arch, platform } from "node:os";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

function getExecutablePath(): string {
    const distDir = join(__dirname, "..", "dist");
    const osType = platform();
    const cpuArch = arch();

    let executableName: string;

    switch (osType) {
        case "linux":
            executableName = "dbmcp-linux-x64";
            break;
        case "win32":
            executableName = "dbmcp-windows-x64.exe";
            break;
        case "darwin":
            executableName = cpuArch === "arm64" ? "dbmcp-darwin-arm64" : "dbmcp-darwin-x64";
            break;
        default:
            throw new Error(`Unsupported platform: ${osType}`);
    }

    const executablePath = join(distDir, executableName);

    if (!existsSync(executablePath)) {
        throw new Error(`Executable not found: ${executablePath}`);
    }

    return executablePath;
}

function main() {
    try {
        const executablePath = getExecutablePath();
        const args = process.argv.slice(2);

        const child = spawn(executablePath, args, {
            stdio: "inherit",
            env: process.env,
        });

        child.on("exit", (code) => {
            process.exit(code || 0);
        });

        child.on("error", (error) => {
            console.error("Error executing dbmcp:", error.message);
            process.exit(1);
        });
    } catch (error) {
        console.error("Error:", error instanceof Error ? error.message : String(error));
        process.exit(1);
    }
}

if (import.meta.url === `file://${process.argv[1]}`) {
    main();
}
