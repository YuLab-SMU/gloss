import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { viteSingleFile } from "vite-plugin-singlefile";
import path from "node:path";

const isLite = process.env.VITE_WORKBENCH_MODE === "lite";

export default defineConfig({
  plugins: [react(), tailwindcss(), viteSingleFile()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
      ...(isLite
        ? {
            "@rive-app/react-canvas": path.resolve(
              __dirname,
              "./src/components/rive/riveStub.ts"
            ),
          }
        : {}),
    },
  },
  build: {
    outDir: isLite ? "dist-lite" : "dist-singlefile",
    assetsInlineLimit: 100_000_000,
    cssCodeSplit: false,
    rollupOptions: {
      output: {
        inlineDynamicImports: true,
      },
    },
  },
});
