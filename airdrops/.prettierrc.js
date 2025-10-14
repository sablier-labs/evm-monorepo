const baseConfig = require("@sablier/devkit/prettier");

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