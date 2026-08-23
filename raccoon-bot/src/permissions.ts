export function hasRaccoonStaffAccess(input: {
  isAdministrator: boolean;
  roleIds: readonly string[];
  moderatorRoleId?: string;
}): boolean {
  return input.isAdministrator || Boolean(input.moderatorRoleId && input.roleIds.includes(input.moderatorRoleId));
}
