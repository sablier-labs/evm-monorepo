/**
 * @type {import("lint-staged").Configuration}
 */
module.exports = {
  "*.{json,md,yml}": "prettier --cache --write",
  "*.sol": ["bun solhint --cache --fix --noPrompt", "forge fmt"],
};
