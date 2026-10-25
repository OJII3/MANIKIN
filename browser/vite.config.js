import { defineConfig } from 'vite'
import moonbit from 'vite-plugin-moonbit'
import { fileURLToPath } from 'node:url'

export default defineConfig({
  plugins: [moonbit({ root: '../moonbit', target: 'js' })],
  resolve: {
    alias: {
      'onnxruntime-web/webgpu': fileURLToPath(new URL('./node_modules/onnxruntime-web/dist/ort.webgpu.bundle.min.mjs', import.meta.url)),
      'onnxruntime-web': fileURLToPath(new URL('./node_modules/onnxruntime-web/dist/ort.min.mjs', import.meta.url)),
    },
  },
})
