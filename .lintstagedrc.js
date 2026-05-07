/**
 * @type {import("lint-staged").Configuration}
 */
module.exports = {
  "*.{json,md,svg,yml}": "bun prettier --cache --write",
  "*.sol": () => "just full-write-all",
};
