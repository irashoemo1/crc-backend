const { defineConfig } = require("cypress");

module.exports = defineConfig({
    projectId: "qxo2p9",
    e2e: {
        setupNodeEvents(on, config) {
            // implement node event listeners here
        },
        baseUrl: "https://aqz2aoirg0.execute-api.us-east-2.amazonaws.com/dev/visitors"
    },
});