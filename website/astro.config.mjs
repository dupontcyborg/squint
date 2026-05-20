import { defineConfig } from "astro/config";

export default defineConfig({
    output: "static",
    trailingSlash: "always",
    site: "https://squint.sh",
    prefetch: {
        prefetchAll: true,
        defaultStrategy: "hover",
    },
});
