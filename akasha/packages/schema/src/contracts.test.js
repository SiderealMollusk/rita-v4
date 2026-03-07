import { describe, expect, it } from 'vitest';

import { assertNodeColor, NODE_COLORS, validateNodeSpec } from './contracts.js';

describe('contracts', () => {
  it('returns a valid node color', () => {
    expect(assertNodeColor('green')).toBe('green');
    expect(NODE_COLORS).toEqual(['green', 'yellow', 'red', 'unknown']);
  });

  it('throws on invalid node color', () => {
    expect(() => assertNodeColor('blue')).toThrow('Invalid node color: blue');
  });

  it('validates a correct node spec', () => {
    expect(validateNodeSpec({ id: 'node-1', checks: [] })).toEqual({
      id: 'node-1',
      checks: []
    });
  });

  it('throws when node spec is not an object', () => {
    expect(() => validateNodeSpec(null)).toThrow('Node spec must be an object');
  });

  it('throws when node spec id is invalid', () => {
    expect(() => validateNodeSpec({ id: '', checks: [] })).toThrow(
      'Node spec id must be a non-empty string'
    );
  });

  it('throws when node spec checks is not an array', () => {
    expect(() => validateNodeSpec({ id: 'node-1', checks: 'bad' })).toThrow(
      'Node spec checks must be an array'
    );
  });
});
