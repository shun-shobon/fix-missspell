import { startBot } from "./deps.ts";

import { spells } from "./spells.ts";

function dedup<T>(array: Array<T>): Array<T> {
  return [...new Set(array)];
}

async function main() {
  const token = Deno.env.get("DISCORD_TOKEN");
  if (token === undefined) {
    throw new Error("DISCORD_TOKEN is not defined in environment variable.");
  }

  await startBot({
    token,
    intents: ["Guilds", "GuildMessages"],
    eventHandlers: {
      async messageCreate(message) {
        if (message.isBot) return;

        const missings = dedup(spells.flatMap((spell) => {
          const regex = new RegExp(spell.name, "ig");

          return Array.from(message.content.matchAll(regex))
            .map(([match]) => match)
            .filter(
              (match) => match !== spell.name && match !== match.toLowerCase(),
            )
            .map((match) => `${spell.name}. Not ${match}.`);
        }));

        if (missings.length === 0) return;

        const reply = missings.join("\n");

        await message.reply(reply);
      },
    },
  });
}

await main();
