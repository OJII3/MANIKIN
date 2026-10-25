import { defineConfig } from 'vite'
import moonbit from 'vite-plugin-moonbit'
import { createReadStream, existsSync, readFileSync } from 'node:fs'
import { fileURLToPath } from 'node:url'

const modelPath = fileURLToPath(new URL('../model_zoo/manikin_s_amass.onnx', import.meta.url))

const localModel = {
  name: 'manikin-local-model',
  configureServer(server) {
    server.middlewares.use('/manikin_s_amass.onnx', (request, response, next) => {
      if (request.method !== 'GET' || !existsSync(modelPath)) return next()
      response.setHeader('Content-Type', 'application/octet-stream')
      createReadStream(modelPath).pipe(response)
    })
  },
  generateBundle() {
    if (existsSync(modelPath)) {
      this.emitFile({
        type: 'asset',
        fileName: 'manikin_s_amass.onnx',
        source: readFileSync(modelPath),
      })
    }
  },
}

export default defineConfig({
  plugins: [moonbit({ root: '../moonbit', target: 'js' }), localModel],
  resolve: {
    alias: {
      'onnxruntime-web/webgpu': fileURLToPath(new URL('./node_modules/onnxruntime-web/dist/ort.webgpu.bundle.min.mjs', import.meta.url)),
      'onnxruntime-web': fileURLToPath(new URL('./node_modules/onnxruntime-web/dist/ort.min.mjs', import.meta.url)),
    },
  },
})
