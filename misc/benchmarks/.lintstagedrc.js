/**
 * @type {import("lint-staged").Configuration}
 */
module.exports = {
  "*.{js,json,yml}": "prettier --cache --write",
  "*.md": ["bun ./scripts/format-numbers.js", "prettier --cache --write"],
  "*.sol": ["bun solhint --cache --fix --noPrompt", "forge fmt"],
};
