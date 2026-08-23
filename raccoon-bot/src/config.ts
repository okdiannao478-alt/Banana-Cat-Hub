import "dotenv/config";

function required(name: string): string {
  const value = process.env[name]?.trim();
  if (!value || value === "XXX") {
    throw new Error(`Missing required environment variable: ${name}. Copy .env.example to .env and fill it locally.`);
  }
  return value;
}

function optional(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return !value || value === "XXX" ? undefined : value;
}

export const config = {
  token: required("DISCORD_BOT_TOKEN"),
  clientId: required("DISCORD_CLIENT_ID"),
  guildId: optional("DISCORD_GUILD_ID"),
  moderatorRoleId: optional("RACCOON_MODERATOR_ROLE_ID"),
  databasePath: process.env.DATABASE_PATH?.trim() || "./data/raccoon.sqlite",
} as const;
