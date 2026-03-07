import { describe, expect, it } from 'vitest';

import { computeNodeState } from './reducer.js';

describe('computeNodeState', () => {
  const healthyChecks = [{ id: 'http', ok: true }];

  it('returns unknown when checks are missing', () => {
    expect(computeNodeState({ checks: [], docsPass: true, reachable: true })).toEqual({
      color: 'unknown',
      why: ['missing_or_stale_evidence'],
      failedChecks: []
    });
  });

  it('returns unknown when evidence is stale', () => {
    expect(
      computeNodeState({ checks: healthyChecks, docsPass: true, reachable: true, isStale: true })
    ).toEqual({
      color: 'unknown',
      why: ['missing_or_stale_evidence'],
      failedChecks: healthyChecks
    });
  });

  it('returns unknown when checks input is not an array', () => {
    expect(computeNodeState({ checks: 'bad', docsPass: true, reachable: true })).toEqual({
      color: 'unknown',
      why: ['missing_or_stale_evidence'],
      failedChecks: []
    });
  });

  it('returns green when all checks and conditions pass', () => {
    expect(computeNodeState({ checks: healthyChecks, docsPass: true, reachable: true })).toEqual({
      color: 'green',
      why: ['all_required_signals_ok'],
      failedChecks: []
    });
  });

  it('returns red when reachability fails', () => {
    expect(computeNodeState({ checks: healthyChecks, docsPass: true, reachable: false })).toEqual({
      color: 'red',
      why: ['critical_path_failed'],
      failedChecks: []
    });
  });

  it('returns red when critical failure is true', () => {
    expect(
      computeNodeState({ checks: healthyChecks, docsPass: true, reachable: true, criticalFailure: true })
    ).toEqual({
      color: 'red',
      why: ['critical_path_failed'],
      failedChecks: []
    });
  });

  it('returns yellow for partial degradation', () => {
    expect(
      computeNodeState({
        checks: [{ id: 'dns', ok: false }],
        docsPass: false,
        reachable: true
      })
    ).toEqual({
      color: 'yellow',
      why: ['partial_degradation'],
      failedChecks: ['dns']
    });
  });
});
