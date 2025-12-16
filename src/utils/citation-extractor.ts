/**
 * Citation Extractor for NotebookLM
 *
 * Extracts source citations by hovering over citation markers [1], [2], etc.
 * and capturing the tooltip content.
 *
 * Features:
 * - Hover-based extraction (no additional API calls)
 * - Multiple output formats (inline, footnotes, json, expanded)
 * - Graceful fallback if citations can't be extracted
 */

import type { Page, ElementHandle } from 'patchright';
import { log } from './logger.js';
import { randomDelay } from './stealth-utils.js';

// ============================================================================
// Types
// ============================================================================

/**
 * Source format options for citation display
 */
export type SourceFormat =
  | 'none' // No source extraction (default, fastest)
  | 'inline' // Insert source text inline: "text [1: source excerpt]"
  | 'footnotes' // Append sources at the end as footnotes
  | 'json' // Return sources as separate JSON object
  | 'expanded'; // Replace [1] with full quoted source text

/**
 * Extracted citation data
 */
export interface Citation {
  /** Citation marker (e.g., "[1]", "[2]") */
  marker: string;
  /** Citation number */
  number: number;
  /** Source text from hover tooltip */
  sourceText: string;
  /** Source name/title if available */
  sourceName?: string;
}

/**
 * Result of citation extraction
 */
export interface CitationExtractionResult {
  /** Original answer text */
  originalAnswer: string;
  /** Formatted answer with sources (based on format) */
  formattedAnswer: string;
  /** Extracted citations */
  citations: Citation[];
  /** Format used */
  format: SourceFormat;
  /** Whether extraction was successful */
  success: boolean;
  /** Error message if extraction failed */
  error?: string;
}

// ============================================================================
// CSS Selectors for NotebookLM Citations
// ============================================================================

/**
 * Selectors to find citation markers in the response
 * NotebookLM typically uses superscript numbers or bracketed references
 */
const CITATION_SELECTORS = [
  // Primary: Citation links/buttons
  '.citation-link',
  '.citation-marker',
  '[data-citation]',
  '[data-citation-id]',
  '[data-source-id]',
  // Superscript numbers
  'sup.citation',
  'sup[data-citation]',
  'sup a',
  // Bracketed references [1], [2]
  '.reference-marker',
  '[role="button"][aria-label*="citation"]',
  '[role="button"][aria-label*="source"]',
  // NotebookLM specific (may need adjustment based on actual DOM)
  '.source-citation',
  '.inline-citation',
  'button.citation',
  // Generic clickable citations
  '[class*="citation"]',
  '[class*="source-ref"]',
];

/**
 * Selectors for the tooltip/popover that appears on hover
 */
const TOOLTIP_SELECTORS = [
  // Common tooltip patterns
  '[role="tooltip"]',
  '.tooltip',
  '.popover',
  '.citation-tooltip',
  '.citation-popover',
  '.source-preview',
  '.source-tooltip',
  // Material Design / Google patterns
  '.mdc-tooltip',
  '.mat-tooltip',
  '[class*="tooltip"]',
  '[class*="popover"]',
  // NotebookLM specific
  '.citation-preview',
  '.source-card',
  '.source-snippet',
  '[data-tooltip]',
  '[aria-describedby]',
];

// ============================================================================
// Main Extraction Function
// ============================================================================

/**
 * Extract citations from a NotebookLM response by hovering over citation markers
 *
 * @param page Playwright page instance
 * @param answerText The answer text to process
 * @param responseContainer The container element holding the response
 * @param format Desired output format
 * @returns Extraction result with formatted answer and citations
 */
export async function extractCitations(
  page: Page,
  answerText: string,
  responseContainer: ElementHandle | null,
  format: SourceFormat = 'none'
): Promise<CitationExtractionResult> {
  // Early return if no extraction requested
  if (format === 'none') {
    return {
      originalAnswer: answerText,
      formattedAnswer: answerText,
      citations: [],
      format,
      success: true,
    };
  }

  log.info(`📚 [CITATIONS] Extracting sources (format: ${format})...`);

  const citations: Citation[] = [];

  try {
    // Find citation markers in the response
    const citationElements = await findCitationElements(page, responseContainer);

    if (citationElements.length === 0) {
      log.info(`📚 [CITATIONS] No citation markers found in response`);
      return {
        originalAnswer: answerText,
        formattedAnswer: answerText,
        citations: [],
        format,
        success: true,
      };
    }

    log.info(`📚 [CITATIONS] Found ${citationElements.length} citation markers`);

    // Extract source text for each citation via hover
    for (const { element, marker, number } of citationElements) {
      try {
        const sourceText = await extractSourceViaHover(page, element);

        if (sourceText) {
          citations.push({
            marker,
            number,
            sourceText,
          });
          log.success(`  ✅ [${marker}] Extracted: "${sourceText.substring(0, 50)}..."`);
        } else {
          log.warning(`  ⚠️  [${marker}] Could not extract source text`);
        }
      } catch (error) {
        log.warning(`  ⚠️  [${marker}] Error extracting: ${error}`);
      }

      // Small delay between hovers to avoid detection
      await randomDelay(100, 200);
    }

    // Format the answer based on requested format
    const formattedAnswer = formatAnswerWithSources(answerText, citations, format);

    log.success(`📚 [CITATIONS] Extracted ${citations.length}/${citationElements.length} sources`);

    return {
      originalAnswer: answerText,
      formattedAnswer,
      citations,
      format,
      success: true,
    };
  } catch (error) {
    const errorMessage = error instanceof Error ? error.message : String(error);
    log.error(`❌ [CITATIONS] Extraction failed: ${errorMessage}`);

    return {
      originalAnswer: answerText,
      formattedAnswer: answerText,
      citations: [],
      format,
      success: false,
      error: errorMessage,
    };
  }
}

// ============================================================================
// Helper Functions
// ============================================================================

interface CitationElement {
  element: ElementHandle;
  marker: string;
  number: number;
}

/**
 * Find citation marker elements in the response
 */
async function findCitationElements(
  page: Page,
  container: ElementHandle | null
): Promise<CitationElement[]> {
  const results: CitationElement[] = [];
  const seenNumbers = new Set<number>();

  // Search context: container if available, otherwise full page
  const searchContext = container || page;

  // Try each selector
  for (const selector of CITATION_SELECTORS) {
    try {
      const elements = await searchContext.$$(selector);

      for (const element of elements) {
        try {
          // Get the text content to identify the citation number
          const text = await element.innerText();
          const match = text.match(/\[?(\d+)\]?/);

          if (match) {
            const number = parseInt(match[1], 10);

            // Skip if we've already found this citation
            if (seenNumbers.has(number)) continue;
            seenNumbers.add(number);

            const marker = `[${number}]`;
            results.push({ element, marker, number });
          }
        } catch {
          continue;
        }
      }
    } catch {
      continue;
    }
  }

  // Also try to find citations by regex pattern in the page
  if (results.length === 0) {
    const regexResults = await findCitationsByRegex(page, container);
    results.push(...regexResults);
  }

  // Sort by citation number
  results.sort((a, b) => a.number - b.number);

  return results;
}

/**
 * Find citations using regex matching on text content
 * Fallback method when CSS selectors don't work
 *
 * This improved version:
 * 1. Detects citation markers [n] in the text
 * 2. Finds clickable elements containing those markers
 * 3. Returns element handles for hover extraction
 */
async function findCitationsByRegex(
  page: Page,
  container: ElementHandle | null
): Promise<CitationElement[]> {
  const results: CitationElement[] = [];
  const seenNumbers = new Set<number>();

  try {
    // First, detect unique citation numbers in the response text
    const citationNumbers = await page.evaluate(
      (containerSelector: string | null) => {
        const searchRoot = containerSelector
          ? // @ts-expect-error - document available in browser context
            document.querySelector(containerSelector)
          : // @ts-expect-error - document available in browser context
            document.body;

        if (!searchRoot) return [];

        const text = searchRoot.textContent || '';
        const matches = text.matchAll(/\[(\d+)\]/g);
        const numbers = new Set<number>();

        for (const match of matches) {
          numbers.add(parseInt(match[1], 10));
        }

        return Array.from(numbers).sort((a, b) => a - b);
      },
      container ? '.to-user-container .message-text-content' : null
    );

    log.info(
      `📚 [CITATIONS] Regex found ${citationNumbers.length} unique citation markers: [${citationNumbers.join(', ')}]`
    );

    // For each citation number, try to find a clickable element
    // NotebookLM typically wraps citations in <a>, <button>, or <span> with click handlers
    const searchContext = container || page;

    for (const num of citationNumbers) {
      if (seenNumbers.has(num)) continue;

      // Try multiple strategies to find the citation element
      const strategies = [
        // Strategy 1: Look for links with the citation number
        `a:has-text("[${num}]")`,
        `button:has-text("[${num}]")`,
        `span:has-text("[${num}]")`,
        // Strategy 2: Look for elements with citation-related attributes
        `[data-citation="${num}"]`,
        `[data-source="${num}"]`,
        `[aria-label*="${num}"]`,
        // Strategy 3: Look for superscript elements
        `sup:has-text("${num}")`,
        // Strategy 4: Generic clickable elements with the number
        `[role="button"]:has-text("[${num}]")`,
        `[role="link"]:has-text("[${num}]")`,
      ];

      for (const selector of strategies) {
        try {
          const element = await searchContext.$(selector);
          if (element) {
            const isVisible = await element.isVisible();
            if (isVisible) {
              seenNumbers.add(num);
              results.push({
                element,
                marker: `[${num}]`,
                number: num,
              });
              log.info(`  📌 Found element for [${num}] using selector: ${selector}`);
              break;
            }
          }
        } catch {
          continue;
        }
      }

      // If no element found with specific selectors, try XPath as last resort
      if (!seenNumbers.has(num)) {
        try {
          // Find any element that contains exactly [n]
          const xpath = `//*[contains(text(), '[${num}]')]`;
          const elements = await page.$$(`::-p-xpath(${xpath})`);

          for (const element of elements) {
            try {
              const text = await element.innerText();
              // Make sure it's the citation marker, not just any text with [n]
              if (text.includes(`[${num}]`) && text.length < 50) {
                const isVisible = await element.isVisible();
                if (isVisible) {
                  seenNumbers.add(num);
                  results.push({
                    element,
                    marker: `[${num}]`,
                    number: num,
                  });
                  log.info(`  📌 Found element for [${num}] using XPath fallback`);
                  break;
                }
              }
            } catch {
              continue;
            }
          }
        } catch {
          // XPath failed, continue without this citation
        }
      }

      if (!seenNumbers.has(num)) {
        log.warning(`  ⚠️  Could not find DOM element for [${num}]`);
      }
    }

    log.info(`📚 [CITATIONS] Found ${results.length}/${citationNumbers.length} citation elements`);
  } catch (error) {
    log.warning(`⚠️  [CITATIONS] Regex search failed: ${error}`);
  }

  // Sort by citation number
  results.sort((a, b) => a.number - b.number);

  return results;
}

/**
 * Extract source text by hovering over a citation element
 */
async function extractSourceViaHover(page: Page, element: ElementHandle): Promise<string | null> {
  try {
    // Scroll element into view
    await element.scrollIntoViewIfNeeded();
    await randomDelay(50, 100);

    // Hover over the element
    await element.hover();

    // Wait for tooltip to appear
    await randomDelay(300, 500);

    // Try to find and read the tooltip content
    for (const tooltipSelector of TOOLTIP_SELECTORS) {
      try {
        const tooltip = await page.$(tooltipSelector);
        if (tooltip) {
          const isVisible = await tooltip.isVisible();
          if (isVisible) {
            const text = await tooltip.innerText();
            if (text && text.trim()) {
              // Move mouse away to dismiss tooltip
              await page.mouse.move(0, 0);
              await randomDelay(100, 150);
              return text.trim();
            }
          }
        }
      } catch {
        continue;
      }
    }

    // Fallback: Check for aria-describedby attribute
    try {
      const describedBy = await element.getAttribute('aria-describedby');
      if (describedBy) {
        const tooltipById = await page.$(`#${describedBy}`);
        if (tooltipById) {
          const text = await tooltipById.innerText();
          if (text && text.trim()) {
            await page.mouse.move(0, 0);
            return text.trim();
          }
        }
      }
    } catch {
      // Ignore
    }

    // Move mouse away even if we didn't find content
    await page.mouse.move(0, 0);
    return null;
  } catch (error) {
    log.warning(`⚠️  [CITATIONS] Hover extraction failed: ${error}`);
    return null;
  }
}

// ============================================================================
// Formatting Functions
// ============================================================================

/**
 * Format the answer with extracted sources based on requested format
 */
export function formatAnswerWithSources(
  answer: string,
  citations: Citation[],
  format: SourceFormat
): string {
  if (citations.length === 0 || format === 'none') {
    return answer;
  }

  switch (format) {
    case 'inline':
      return formatInline(answer, citations);
    case 'footnotes':
      return formatFootnotes(answer, citations);
    case 'expanded':
      return formatExpanded(answer, citations);
    case 'json':
      // For JSON format, we return the original answer
      // The citations are available in the result object
      return answer;
    default:
      return answer;
  }
}

/**
 * Format with inline source excerpts: "text [1: source excerpt]"
 *
 * NotebookLM returns citations in different formats:
 * - Superscript numbers without brackets: "text1,2" or "text3"
 * - Sometimes with brackets: "text[1]"
 * - Sometimes stuck together: "text123" (meaning citations 1, 2, 3)
 *
 * This function handles all formats.
 */
function formatInline(answer: string, citations: Citation[]): string {
  let result = answer;

  // Sort citations by number in DESCENDING order to avoid replacing [1] before [10]
  const sortedCitations = [...citations].sort((a, b) => b.number - a.number);

  for (const citation of sortedCitations) {
    const shortSource = truncateSource(citation.sourceText, 100);
    const num = citation.number;
    const inlineReplacement = `[${num}: "${shortSource}"]`;

    // Pattern 1: Bracketed format [n]
    const bracketedPattern = `\\[${num}\\]`;
    if (new RegExp(bracketedPattern).test(result)) {
      result = result.replace(new RegExp(bracketedPattern, 'g'), inlineReplacement);
      continue;
    }

    // Pattern 2: Superscript format - number followed by comma/period/space/newline/end
    // Also handles citations stuck together by using lookahead for next digit or punctuation
    // Match: "word1," or "word1." or "word12" (where we want to match the 1)
    const superscriptPattern = `(\\D)(${num})(?=[,\\.;:\\s\\n]|(?=\\d)|$)`;
    if (new RegExp(superscriptPattern).test(result)) {
      result = result.replace(new RegExp(superscriptPattern, 'g'), `$1${inlineReplacement}`);
    }
  }

  return result;
}

/**
 * Format with footnotes at the end
 */
function formatFootnotes(answer: string, citations: Citation[]): string {
  if (citations.length === 0) return answer;

  const footnotes = citations
    .map((c) => {
      const source = c.sourceName ? `${c.sourceName}: ` : '';
      return `${c.marker} ${source}${c.sourceText}`;
    })
    .join('\n\n');

  return `${answer}\n\n---\n**Sources:**\n${footnotes}`;
}

/**
 * Format with expanded inline quotes replacing markers
 *
 * Handles bracketed [n], superscript n, and stuck-together formats.
 */
function formatExpanded(answer: string, citations: Citation[]): string {
  let result = answer;

  // Sort citations by number in DESCENDING order to avoid replacing 1 before 10
  const sortedCitations = [...citations].sort((a, b) => b.number - a.number);

  for (const citation of sortedCitations) {
    const shortSource = truncateSource(citation.sourceText, 150);
    const replacement = `"${shortSource}"`;
    const num = citation.number;

    // Pattern 1: Bracketed format [n]
    const bracketedPattern = `\\[${num}\\]`;
    if (new RegExp(bracketedPattern).test(result)) {
      result = result.replace(new RegExp(bracketedPattern, 'g'), replacement);
      continue;
    }

    // Pattern 2: Superscript format - also handles stuck-together citations
    const superscriptPattern = `(\\D)(${num})(?=[,\\.;:\\s\\n]|(?=\\d)|$)`;
    if (new RegExp(superscriptPattern).test(result)) {
      result = result.replace(new RegExp(superscriptPattern, 'g'), `$1${replacement}`);
    }
  }

  return result;
}

/**
 * Truncate source text to a reasonable length
 */
function truncateSource(text: string, maxLength: number): string {
  if (text.length <= maxLength) return text;
  return text.substring(0, maxLength - 3) + '...';
}

// ============================================================================
// Exports
// ============================================================================

export default {
  extractCitations,
  formatAnswerWithSources,
};
