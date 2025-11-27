export const normalizeOrgId = (orgId) => {
  if (!orgId) {
    return '';
  }

  const trimmed = orgId.trim();
  if (!trimmed) {
    return '';
  }

  const isAddress =
    /^0x[a-fA-F0-9]{40}$/.test(trimmed);

  return isAddress ? trimmed.toLowerCase() : trimmed;
};

export default normalizeOrgId;


