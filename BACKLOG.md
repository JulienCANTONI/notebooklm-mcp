# Backlog

## High Priority

### list-notebooks-from-nblm
**Status:** To Do
**Description:** Add a function to scrape the NotebookLM homepage to get a real list of notebooks with their actual IDs and names, instead of relying on cached/configured notebook IDs.

**Use case:** When running E2E tests or managing notebooks, we need to know which notebooks actually exist in each account.

**Implementation notes:**
- Navigate to NotebookLM homepage
- Parse notebook cards to extract IDs and titles
- Return structured list with notebook_id, title, last_modified

### /notebooks/:id/share endpoint
**Status:** To Do
**Description:** Add an API endpoint to share notebooks between accounts programmatically.

**Use case:** E2E tests need shared notebooks across the 3 test accounts. Currently this must be done manually in the NotebookLM UI.

**Implementation notes:**
- Navigate to notebook settings
- Add email addresses with editor permissions
- Confirm sharing

## Medium Priority

### Cleanup test notebooks
**Status:** To Do
**Description:** Delete unused notebooks in test accounts (100 notebook limit reached).

**Notes:**
- mathieudumont31@gmail.com
- rpmonster@gmail.com
- rom1pey@gmail.com

## Low Priority

_None currently_

---
*Last updated: 2026-01-01*
