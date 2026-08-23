import Database from "better-sqlite3";
import { createHash, randomBytes } from "node:crypto";
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";

export const RESET_COOLDOWN_MS = 20 * 60 * 1000;
const ALPHANUMERIC = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";

export type PurchaseCodeRecord = {
  codeHash: string;
  createdByDiscordId: string;
  createdAt: number;
  redeemedByDiscordId: string | null;
  redeemedAt: number | null;
};

export type LicenseRecord = {
  discordUserId: string;
  longKeyHash: string;
  longKeyLast4: string;
  deviceHash: string | null;
  redeemedAt: number;
  lastResetAt: number | null;
};

export function hashValue(value: string): string {
  return createHash("sha256").update(value.trim()).digest("hex");
}

export function createRandomCode(length = 8): string {
  const bytes = randomBytes(length);
  let result = "";
  for (const byte of bytes) result += ALPHANUMERIC[byte % ALPHANUMERIC.length];
  return result;
}

export function createLongKey(length = 25): string {
  return createRandomCode(length);
}

export class LicenseDatabase {
  private readonly db: Database.Database;

  constructor(filePath: string) {
    mkdirSync(dirname(filePath), { recursive: true });
    this.db = new Database(filePath);
    this.db.pragma("journal_mode = WAL");
    this.db.pragma("foreign_keys = ON");
    this.db.exec(`
      CREATE TABLE IF NOT EXISTS settings (
        guild_id TEXT PRIMARY KEY,
        redemption_channel_id TEXT NOT NULL,
        panel_message_id TEXT,
        updated_at INTEGER NOT NULL
      );
      CREATE TABLE IF NOT EXISTS purchase_codes (
        code_hash TEXT PRIMARY KEY,
        created_by_discord_id TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        redeemed_by_discord_id TEXT,
        redeemed_at INTEGER
      );
      CREATE TABLE IF NOT EXISTS licenses (
        discord_user_id TEXT PRIMARY KEY,
        long_key_hash TEXT NOT NULL UNIQUE,
        long_key_last4 TEXT NOT NULL,
        device_hash TEXT,
        redeemed_at INTEGER NOT NULL,
        last_reset_at INTEGER
      );
      CREATE INDEX IF NOT EXISTS idx_purchase_redeemed ON purchase_codes(redeemed_by_discord_id);
    `);
  }

  close(): void {
    this.db.close();
  }

  setRedemptionChannel(guildId: string, channelId: string, messageId: string | null): void {
    this.db.prepare(`
      INSERT INTO settings (guild_id, redemption_channel_id, panel_message_id, updated_at)
      VALUES (?, ?, ?, ?)
      ON CONFLICT(guild_id) DO UPDATE SET
        redemption_channel_id = excluded.redemption_channel_id,
        panel_message_id = excluded.panel_message_id,
        updated_at = excluded.updated_at
    `).run(guildId, channelId, messageId, Date.now());
  }

  getRedemptionChannel(guildId: string): { channelId: string; messageId: string | null } | null {
    const row = this.db.prepare(`SELECT redemption_channel_id as channelId, panel_message_id as messageId FROM settings WHERE guild_id = ?`).get(guildId) as { channelId: string; messageId: string | null } | undefined;
    return row ?? null;
  }

  createPurchaseCodes(count: number, createdByDiscordId: string): string[] {
    const insert = this.db.prepare(`INSERT INTO purchase_codes (code_hash, created_by_discord_id, created_at) VALUES (?, ?, ?)`);
    const codes: string[] = [];
    const transaction = this.db.transaction(() => {
      for (let i = 0; i < count; i += 1) {
        let code = createRandomCode(8);
        while (this.db.prepare(`SELECT 1 FROM purchase_codes WHERE code_hash = ?`).get(hashValue(code))) code = createRandomCode(8);
        insert.run(hashValue(code), createdByDiscordId, Date.now());
        codes.push(code);
      }
    });
    transaction();
    return codes;
  }

  redeemPurchaseCode(rawCode: string, discordUserId: string): { ok: true; license: LicenseRecord; longKey: string } | { ok: false; reason: "invalid" | "already-redeemed" | "already-licensed" } {
    const codeHash = hashValue(rawCode);
    const current = this.db.prepare(`SELECT * FROM purchase_codes WHERE code_hash = ?`).get(codeHash) as PurchaseCodeRecord | undefined;
    if (!current) return { ok: false, reason: "invalid" };
    if (current.redeemedByDiscordId) return { ok: false, reason: "already-redeemed" };
    const existing = this.getLicense(discordUserId);
    if (existing) return { ok: false, reason: "already-licensed" };

    const longKey = createLongKey(25);
    const now = Date.now();
    const license: LicenseRecord = {
      discordUserId,
      longKeyHash: hashValue(longKey),
      longKeyLast4: longKey.slice(-4),
      deviceHash: null,
      redeemedAt: now,
      lastResetAt: null,
    };
    const transaction = this.db.transaction(() => {
      const update = this.db.prepare(`UPDATE purchase_codes SET redeemed_by_discord_id = ?, redeemed_at = ? WHERE code_hash = ? AND redeemed_by_discord_id IS NULL`).run(discordUserId, now, codeHash);
      if (update.changes !== 1) throw new Error("purchase-code-already-redeemed");
      this.db.prepare(`INSERT INTO licenses (discord_user_id, long_key_hash, long_key_last4, device_hash, redeemed_at, last_reset_at) VALUES (?, ?, ?, ?, ?, ?)`).run(license.discordUserId, license.longKeyHash, license.longKeyLast4, null, license.redeemedAt, null);
    });
    try {
      transaction();
      return { ok: true, license, longKey };
    } catch {
      return { ok: false, reason: "already-redeemed" };
    }
  }

  private getLicenseByLongKey(rawLongKey: string): LicenseRecord | null {
    const row = this.db.prepare(`SELECT discord_user_id as discordUserId, long_key_hash as longKeyHash, long_key_last4 as longKeyLast4, device_hash as deviceHash, redeemed_at as redeemedAt, last_reset_at as lastResetAt FROM licenses WHERE long_key_hash = ?`).get(hashValue(rawLongKey)) as LicenseRecord | undefined;
    return row ?? null;
  }

  validateLongKeyDevice(rawLongKey: string, rawDeviceId: string): { ok: true; bound: boolean } | { ok: false; reason: "invalid-key" | "invalid-device" | "different-device" } {
    if (!/^[A-Za-z0-9]{25}$/.test(rawLongKey.trim())) return { ok: false, reason: "invalid-key" };
    if (!rawDeviceId.trim()) return { ok: false, reason: "invalid-device" };
    const license = this.getLicenseByLongKey(rawLongKey);
    if (!license) return { ok: false, reason: "invalid-key" };
    const deviceHash = hashValue(rawDeviceId);
    if (license.deviceHash && license.deviceHash !== deviceHash) return { ok: false, reason: "different-device" };
    if (!license.deviceHash) this.db.prepare(`UPDATE licenses SET device_hash = ? WHERE discord_user_id = ?`).run(deviceHash, license.discordUserId);
    return { ok: true, bound: !license.deviceHash };
  }

  resetDeviceWithLongKey(rawLongKey: string): { ok: true; nextResetAt: number } | { ok: false; reason: "invalid-key" | "cooldown"; nextResetAt?: number } {
    const license = this.getLicenseByLongKey(rawLongKey);
    if (!license) return { ok: false, reason: "invalid-key" };
    const result = this.resetDevice(license.discordUserId);
    if (!result.ok) {
      if (result.reason === "not-licensed") return { ok: false, reason: "invalid-key" };
      return { ok: false, reason: "cooldown", nextResetAt: result.nextResetAt };
    }
    return { ok: true, nextResetAt: result.nextResetAt };
  }

  getLicense(discordUserId: string): LicenseRecord | null {
    const row = this.db.prepare(`SELECT discord_user_id as discordUserId, long_key_hash as longKeyHash, long_key_last4 as longKeyLast4, device_hash as deviceHash, redeemed_at as redeemedAt, last_reset_at as lastResetAt FROM licenses WHERE discord_user_id = ?`).get(discordUserId) as LicenseRecord | undefined;
    return row ?? null;
  }

  bindDevice(discordUserId: string, deviceHash: string): { ok: true } | { ok: false; reason: "not-licensed" | "different-device" } {
    const license = this.getLicense(discordUserId);
    if (!license) return { ok: false, reason: "not-licensed" };
    if (license.deviceHash && license.deviceHash !== deviceHash) return { ok: false, reason: "different-device" };
    this.db.prepare(`UPDATE licenses SET device_hash = ? WHERE discord_user_id = ?`).run(deviceHash, discordUserId);
    return { ok: true };
  }

  bindDeviceWithLongKey(discordUserId: string, rawLongKey: string, rawDeviceId: string): { ok: true } | { ok: false; reason: "not-licensed" | "invalid-key" | "different-device" | "invalid-device" } {
    const deviceHash = hashValue(rawDeviceId);
    if (!rawDeviceId.trim() || deviceHash.length !== 64) return { ok: false, reason: "invalid-device" };
    const license = this.getLicense(discordUserId);
    if (!license) return { ok: false, reason: "not-licensed" };
    if (license.longKeyHash !== hashValue(rawLongKey)) return { ok: false, reason: "invalid-key" };
    if (license.deviceHash && license.deviceHash !== deviceHash) return { ok: false, reason: "different-device" };
    this.db.prepare(`UPDATE licenses SET device_hash = ? WHERE discord_user_id = ?`).run(deviceHash, discordUserId);
    return { ok: true };
  }

  resetDevice(discordUserId: string): { ok: true; nextResetAt: number } | { ok: false; reason: "not-licensed" | "cooldown"; nextResetAt?: number } {
    const license = this.getLicense(discordUserId);
    if (!license) return { ok: false, reason: "not-licensed" };
    const now = Date.now();
    const nextAllowed = (license.lastResetAt ?? 0) + RESET_COOLDOWN_MS;
    if (license.lastResetAt && now < nextAllowed) return { ok: false, reason: "cooldown", nextResetAt: nextAllowed };
    this.db.prepare(`UPDATE licenses SET device_hash = NULL, last_reset_at = ? WHERE discord_user_id = ?`).run(now, discordUserId);
    return { ok: true, nextResetAt: now + RESET_COOLDOWN_MS };
  }

  getStats(): { purchaseCodes: number; redeemedCodes: number; licenses: number } {
    const row = this.db.prepare(`SELECT COUNT(*) as purchaseCodes, SUM(CASE WHEN redeemed_by_discord_id IS NOT NULL THEN 1 ELSE 0 END) as redeemedCodes FROM purchase_codes`).get() as { purchaseCodes: number; redeemedCodes: number | null };
    const licenses = this.db.prepare(`SELECT COUNT(*) as count FROM licenses`).get() as { count: number };
    return { purchaseCodes: row.purchaseCodes, redeemedCodes: row.redeemedCodes ?? 0, licenses: licenses.count };
  }
}
