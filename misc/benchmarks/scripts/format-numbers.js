/**
 * Utility script to format large numbers in markdown files by adding thousand separators.
 * This is particularly useful for gas benchmark documentation where large numbers are common.
 */
const fs = require("node:fs/promises");

// Create a number formatter for US locale with thousand separators
const numberFormatter = new Intl.NumberFormat("en-US");

/**
 * Formats large numbers in a markdown file by adding thousand separators.
 * @param {string} filePath - Path to the markdown file to format
 */
async function format(filePath) {
  try {
    // Read the markdown file content
    const markdownContent = await fs.readFile(filePath, "utf8");

    // Replace large numbers with formatted versions that include thousand separators
    // Using a regex that matches numbers with 5 or more digits
    const formattedContent = markdownContent.replace(/\b\d{5,}\b/g, (match) => {
      return numberFormatter.format(Number.parseInt(match));
    });

    // Write the formatted content back to the file
    await fs.writeFile(filePath, formattedContent);
    console.log(`\x1b[32m✓\x1b[0m Formatted: ${filePath}`);
  } catch (error) {
    if (error.code === "ENOENT") {
      console.warn(`\x1b[33m⚠\x1b[0m Warning: File not found, skipping: ${filePath}`);
    } else {
      console.warn(`\x1b[31m⚠\x1b[0m Warning: Error processing ${filePath}: ${error.message}`);
    }
  }
}

(async () => {
  await format("results/flow/flow.md");
  await format("results/lockup/batch-lockup.md");
  await format("results/lockup/lockup-dynamic.md");
  await format("results/lockup/lockup-linear.md");
  await format("results/lockup/lockup-tranched.md");
})();
