import { readFileSync } from "node:fs";

const rows = {};
for (const line of readFileSync(0, "utf8").split("\n")) {
	const match = line.match(/^([+-])\s+"([^"]+)": \{.*"commit": "([0-9a-f]{7})/);
	if (match) (rows[match[2]] ??= {})[match[1]] = match[3];
}
for (const [name, { "-": from, "+": to }] of Object.entries(rows)) {
	console.log(`- \`${name}\`: ${from ?? "new"} -> ${to ?? "removed"}`);
}
