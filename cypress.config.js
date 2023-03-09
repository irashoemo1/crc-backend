const { defineConfig } = require("cypress");

module.exports = defineConfig({
    e2e: {
        setupNodeEvents(on, config) {
            // implement node event listeners here
        },
        baseUrl: "https://aqz2aoirg0.execute-api.us-east-2.amazonaws.com/dev/visitors",
        supportFile: false
    },
});