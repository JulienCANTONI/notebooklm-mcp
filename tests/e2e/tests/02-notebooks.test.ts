/**
 * Notebook Library Tests
 *
 * Tests: 4-10
 * Category: Notebook Library
 */

import { describe, it, expect } from '@jest/globals';
import { httpRequest } from '../utils.js';
import { currentNotebooks } from '../config.js';

// Use configured notebook or fallback
const TEST_NOTEBOOK_ID = 'notebook-1';

describe('02 - Notebook Library', () => {
  it('[T04] Should list notebooks', async () => {
    const result = await httpRequest('/notebooks');

    expect(result.success).toBe(true);
    expect((result.data as { notebooks: unknown[] }).notebooks).toBeInstanceOf(Array);
    expect((result.data as { notebooks: unknown[] }).notebooks.length).toBeGreaterThan(0);
  });

  it('[T05] Should have test notebook configured', async () => {
    const result = await httpRequest('/notebooks');
    const notebooks = (result.data as { notebooks: Array<{ id: string; name: string }> }).notebooks;

    const testNotebook = notebooks.find((n) => n.id === TEST_NOTEBOOK_ID);
    expect(testNotebook).toBeDefined();
    expect(testNotebook?.name).toBeTruthy();
  });

  it('[T06] Should get notebook details', async () => {
    const result = await httpRequest(`/notebooks/${TEST_NOTEBOOK_ID}`);

    expect(result.success).toBe(true);
    expect((result.data as { notebook: { id: string } }).notebook.id).toBe(TEST_NOTEBOOK_ID);
  });

  it('[T07] Should activate notebook', async () => {
    const result = await httpRequest(`/notebooks/${TEST_NOTEBOOK_ID}/activate`, 'PUT');

    expect(result.success).toBe(true);
  });

  it('[T08] Should get library statistics', async () => {
    const result = await httpRequest('/notebooks/stats');

    expect(result.success).toBe(true);
    const data = result.data as { total_notebooks: number };
    expect(data.total_notebooks).toBeGreaterThan(0);
  });

  it('[T09] Should search notebooks by topic', async () => {
    const result = await httpRequest('/notebooks/search?query=CNV');

    expect(result.success).toBe(true);
    const data = result.data as { notebooks: Array<{ id: string }> };
    expect(data.notebooks).toBeInstanceOf(Array);
  });

  it('[T10] Should update notebook metadata', async () => {
    const timestamp = new Date().toISOString();
    const result = await httpRequest(`/notebooks/${TEST_NOTEBOOK_ID}`, 'PUT', {
      description: `E2E test update ${timestamp}`,
    });

    expect(result.success).toBe(true);
  });
});
