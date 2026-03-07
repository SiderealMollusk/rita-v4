import React from 'react';
import { render, screen, waitFor } from '@testing-library/react';
import { Effect } from 'effect';
import { describe, expect, it } from 'vitest';

import App from './App.jsx';

describe('App', () => {
  it('renders ready state from successful health load', async () => {
    const loadHealth = () => Effect.succeed({ service: 'akasha-api' });

    render(<App loadHealth={loadHealth} />);

    await waitFor(() => {
      expect(screen.getByText('API: akasha-api')).toBeDefined();
    });
  });

  it('renders error state when health load fails', async () => {
    const loadHealth = () => Effect.fail(new Error('boom'));

    render(<App loadHealth={loadHealth} />);

    await waitFor(() => {
      expect(screen.getByText('boom')).toBeDefined();
    });
  });

  it('renders loading state before effect resolves', () => {
    const loadHealth = () => Effect.never;

    const view = render(<App loadHealth={loadHealth} />);

    expect(screen.getByText('Loading health...')).toBeDefined();

    view.unmount();
  });
});
