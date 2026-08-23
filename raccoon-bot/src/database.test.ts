import { afterEach, describe, expect, it } from "vitest";
import { mkdtempSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { LicenseDatabase, RESET_COOLDOWN_MS, createLongKey } from "./database.js";

const tempDirs: string[] = [];
const databases: LicenseDatabase[] = [];

afterEach(() => {
  for (const database of databases.splice(0)) database.close();
  for (const directory of tempDirs.splice(0)) rmSync(directory, { recursive: true, force: true });
});

function createDatabase(): LicenseDatabase {
  const directory = mkdtempSync(join(tmpdir(), "raccoon-license-"));
  tempDirs.push(directory);
  const database = new LicenseDatabase(join(directory, "raccoon.sqlite"));
  databases.push(database);
  return database;
}

describe("Raccoon license database", () => {
  it("creates 25-character alphanumeric long keys", () => {
    const key = createLongKey(25);
    expect(key).toHaveLength(25);
    expect(key).toMatch(/^[A-Za-z0-9]+$/);
  });

  it("redeems a short purchase code once and creates a permanent license", () => {
    const database = createDatabase();
    const [purchaseCode] = database.createPurchaseCodes(1, "staff-1");
    const first = database.redeemPurchaseCode(purchaseCode, "player-1");
    expect(first.ok).toBe(true);
    if (!first.ok) return;
    expect(first.longKey).toHaveLength(25);
    expect(database.redeemPurchaseCode(purchaseCode, "player-2")).toEqual({ ok: false, reason: "already-redeemed" });
    expect(database.redeemPurchaseCode("not-a-code", "player-3")).toEqual({ ok: false, reason: "invalid" });
  });

  it("allows only one device until a successful reset", () => {
    const database = createDatabase();
    const [purchaseCode] = database.createPurchaseCodes(1, "staff-1");
    expect(database.redeemPurchaseCode(purchaseCode, "player-1")).toMatchObject({ ok: true });
    expect(database.bindDevice("player-1", "device-a")).toEqual({ ok: true });
    expect(database.bindDevice("player-1", "device-b")).toEqual({ ok: false, reason: "different-device" });
    expect(database.resetDevice("player-1")).toMatchObject({ ok: true });
    expect(database.bindDevice("player-1", "device-b")).toEqual({ ok: true });
  });

  it("enforces a 20-minute reset cooldown without approval", () => {
    const database = createDatabase();
    const [purchaseCode] = database.createPurchaseCodes(1, "staff-1");
    database.redeemPurchaseCode(purchaseCode, "player-1");
    const first = database.resetDevice("player-1");
    expect(first.ok).toBe(true);
    if (!first.ok) return;
    const second = database.resetDevice("player-1");
    expect(second).toMatchObject({ ok: false, reason: "cooldown" });
    expect(second.ok === false && second.nextResetAt).toBeGreaterThan(Date.now() + RESET_COOLDOWN_MS - 1000);
  });

  it("rejects reset for a player without a redeemed code", () => {
    const database = createDatabase();
    expect(database.resetDevice("unknown-player")).toEqual({ ok: false, reason: "not-licensed" });
  });
});
