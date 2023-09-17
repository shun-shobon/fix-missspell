#!/usr/bin/env bun

import { Client } from "discord.js";
import { spells } from "./spells";

function dedup<T>(array: Array<T>): Array<T> {
  return [...new Set(array)];
}

const app = new Client({
  intents: ["Guilds", "GuildMessages", "MessageContent"],
});

app.on("ready", (client) => {
  console.log(`Logged in as ${client.user?.tag}`);
});

app.on("messageCreate", async (message) => {
  if (message.author.bot) return;

  const missings = dedup(
    spells.flatMap((spell) => {
      const regex = new RegExp(spell.name, "iug");

      return Array.from(message.content.matchAll(regex))
        .map(([match]) => match)
        .filter(
          (match) => match !== spell.name && match !== match.toLowerCase()
        )
        .map((match) => `${spell.name}. Not ${match}.`);
    })
  );

  if (missings.length === 0) return;

  console.log(`Found ${missings.length} missings`);

  const reply = missings.join("\n");

  await message.reply(reply);
});

async function stop() {
  console.log("Stopping...");
  await app.destroy();
  process.exit(0);
}

process.on("SIGINT", stop);
process.on("SIGTERM", stop);

await app.login(Bun.env.DISCORD_TOKEN);
