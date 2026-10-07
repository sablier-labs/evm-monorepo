/**
 * @notice Lint CIs run from within the protocol directories. So, prettier needs to resolve devkit from the protocol's
 * node_modules folder.
 */
const fs = require("node:fs");
const path = require("node:path");

function resolveDevkit() {
  for (const dir of [".", "airdrops", "bob", "flow", "lockup", "utils"]) {
    const file = path.join(__dirname, dir, "node_modules/@prb/devkit/.prettierrc.json");
    if (fs.existsSync(file)) {
      return JSON.parse(fs.readFileSync(file, "utf8"));
    }
  }
}

const baseConfig = resolveDevkit();

/**
 * @see https://prettier.io/docs/configuration
 * @type {import("prettier").Config}
 */
const config = {
  ...baseConfig,
  overrides: [
    ...(baseConfig.overrides || []),
    {
      files: "*.svg",
      options: {
        parser: "html",
      },
    },
  ],
};

module.exports = config;
