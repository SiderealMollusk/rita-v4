import { describe, expect, it } from 'vitest';

import { colorForState } from './status-light.js';

describe('colorForState', () => {
  it('maps states to colors', () => {
    expect(colorForState('green')).toBe('#25a85a');
    expect(colorForState('yellow')).toBe('#f0b429');
    expect(colorForState('red')).toBe('#d64545');
    expect(colorForState('unknown')).toBe('#6b7280');
  });
});
