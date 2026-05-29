import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";
import { fileURLToPath, URL } from "url"

// https://vite.dev/config/
export default defineConfig({
  plugins: [
    tailwindcss(),
    react(),
  ],
  resolve: {
    extensions: ['.jsx', '.js', '.ts', '.tsx'],
    alias: {
      "@": fileURLToPath(new URL('./src', import.meta.url)),
      "@c": fileURLToPath(new URL("./src/components", import.meta.url)),
    },
  },
  server: {
    proxy: {
      '/api': {
        target: 'http://localhost:3000',
        changeOrigin: true,
        bypass: (req) => req.headers.accept?.includes('text/html') ? '/' : null
      }
    }
  }
})
