import { assertNodeColor } from '@akasha/schema';

export function computeNodeState(input) {
  const checks = Array.isArray(input.checks) ? input.checks : [];
  const hasChecks = checks.length > 0;
  const stale = input.isStale === true;

  if (!hasChecks || stale) {
    return buildState('unknown', ['missing_or_stale_evidence'], checks);
  }

  const failed = checks.filter((check) => check.ok !== true).map((check) => check.id);

  if (input.reachable === false || input.criticalFailure === true) {
    return buildState('red', ['critical_path_failed'], failed);
  }

  if (failed.length === 0 && input.docsPass === true && input.reachable === true) {
    return buildState('green', ['all_required_signals_ok'], failed);
  }

  return buildState('yellow', ['partial_degradation'], failed);
}

function buildState(color, why, failedChecks) {
  return {
    color: assertNodeColor(color),
    why,
    failedChecks
  };
}
