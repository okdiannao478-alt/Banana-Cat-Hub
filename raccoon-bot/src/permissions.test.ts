import { describe, expect, it } from "vitest";
import { hasRaccoonStaffAccess } from "./permissions.js";

describe("Raccoon staff access", () => {
  it("allows administrators", () => {
    expect(hasRaccoonStaffAccess({ isAdministrator: true, roleIds: [], moderatorRoleId: "mod" })).toBe(true);
  });

  it("allows the configured moderator role", () => {
    expect(hasRaccoonStaffAccess({ isAdministrator: false, roleIds: ["member", "mod"], moderatorRoleId: "mod" })).toBe(true);
  });

  it("rejects regular members and missing moderator configuration", () => {
    expect(hasRaccoonStaffAccess({ isAdministrator: false, roleIds: ["member"], moderatorRoleId: "mod" })).toBe(false);
    expect(hasRaccoonStaffAccess({ isAdministrator: false, roleIds: ["mod"] })).toBe(false);
  });
});
