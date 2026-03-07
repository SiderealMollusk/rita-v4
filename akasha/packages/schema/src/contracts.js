export const NODE_COLORS = ['green', 'yellow', 'red', 'unknown'];

export function assertNodeColor(color) {
  if (NODE_COLORS.includes(color)) {
    return color;
  }

  throw new Error(`Invalid node color: ${String(color)}`);
}

export function validateNodeSpec(spec) {
  if (!spec || typeof spec !== 'object') {
    throw new Error('Node spec must be an object');
  }

  if (typeof spec.id !== 'string' || spec.id.length === 0) {
    throw new Error('Node spec id must be a non-empty string');
  }

  if (!Array.isArray(spec.checks)) {
    throw new Error('Node spec checks must be an array');
  }

  return {
    id: spec.id,
    checks: spec.checks
  };
}
