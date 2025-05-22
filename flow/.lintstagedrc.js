/**
 * @type {import("lint-staged").Configuration}
 */
module.exports = {
  "*.{json,md,svg,yml}": "prettier --cache --write",
  "*.sol": [
    "bun solhint --fix --noPrompt",
    "forge fmt",
  ],
};
