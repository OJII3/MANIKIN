import './style.css'
import { infer } from 'mbt:ojii3/manikin-moonbit/src'

const app = document.querySelector('#app')
const identity = [1, 0, 0, 0, 1, 0]
let modelUrl = '/manikin_s_amass.onnx'
let input = makeNeutralInput()
let result = null

app.innerHTML = `
  <header class="topbar">
    <a class="wordmark" href="/">M<span>/</span></a>
    <div class="top-meta"><span class="live-dot"></span> BROWSER INFERENCE <span class="divider">/</span> MOONBIT · ONNX</div>
    <a class="repo-link" href="https://github.com/OJII3/MANIKIN" target="_blank" rel="noreferrer">SOURCE ↗</a>
  </header>
  <section class="hero">
    <div class="eyebrow">FULL BODY TRACKING / 01</div>
    <h1>Move with<br><i>less.</i></h1>
    <div class="hero-foot"><p>Head and hands in.<br>Full body out.</p><span class="hero-index">MANIKIN S<br>WEBGPU RUNTIME</span></div>
    <div class="orb orb-one"></div><div class="orb orb-two"></div>
  </section>
  <section class="workspace">
    <div class="section-heading"><span>01 / CONFIGURE</span><span>MODEL + TRACKER WINDOW</span></div>
    <div class="config-grid">
      <article class="panel model-panel">
        <div class="panel-title"><span class="number">A</span><div><h2>Model graph</h2><p>MANIKIN-S · ONNX</p></div></div>
        <label class="dropzone" for="model-file"><span class="drop-icon">↑</span><strong id="model-label">model_zoo/manikin_s_amass.onnx</strong><small>or choose another model / enter a URL</small><input id="model-file" type="file" accept=".onnx,application/octet-stream" /></label>
        <input class="text-input" id="model-url" placeholder="https://…/manikin_s.onnx" />
        <div class="runtime-row"><span>Execution provider</span><span class="provider"><span class="live-dot"></span> WEBGPU</span></div>
        <div class="runtime-row"><span>Adapter</span><span id="gpu-state" class="muted">Checking…</span></div>
      </article>
      <article class="panel input-panel">
        <div class="panel-title"><span class="number">B</span><div><h2>Tracker window</h2><p>40 FRAMES · 54 FLOATS / FRAME</p></div></div>
        <div class="tracker-row"><div class="tracker-icon">H</div><div><b>Headset</b><small>Orientation + position + velocity</small></div><span>18</span></div>
        <div class="tracker-row"><div class="tracker-icon hand">L</div><div><b>Left hand</b><small>Orientation + position + velocity</small></div><span>18</span></div>
        <div class="tracker-row"><div class="tracker-icon hand">R</div><div><b>Right hand</b><small>Orientation + position + velocity</small></div><span>18</span></div>
        <div class="input-actions"><label class="button secondary" for="input-file">LOAD CSV / JSON<input id="input-file" type="file" accept=".csv,.json,text/csv,application/json" /></label><button class="text-button" id="sample-button">USE NEUTRAL SAMPLE ↗</button></div>
        <div class="input-note" id="input-state">Neutral sample loaded · 40 × 54</div>
      </article>
    </div>
    <div class="runbar"><div><span class="run-indicator"></span><span id="status">Ready to infer</span></div><button id="run-button" class="button primary">RUN INFERENCE <span>↗</span></button></div>
  </section>
  <section class="results" id="results">
    <div class="section-heading"><span>02 / OUTPUT</span><span>NETWORK PREDICTIONS</span></div>
    <div id="result-content" class="empty-state"><div class="empty-mark">M<span>/</span></div><p>Four predictions, one compact model.</p><small>Run inference to inspect the output tensors.</small></div>
  </section>
  <footer><span>MANIKIN S / IN-BROWSER INFERENCE</span><span>POWERED BY MOONBIT + ONNX RUNTIME WEB</span></footer>
`

const $ = (selector) => document.querySelector(selector)
const status = $('#status')
const runButton = $('#run-button')

function makeNeutralInput() {
  const data = new Array(40 * 54).fill(0)
  for (let frame = 0; frame < 40; frame++) {
    for (let tracker = 0; tracker < 3; tracker++) {
      data.splice(frame * 54 + tracker * 6, 6, ...identity)
    }
  }
  return data
}

async function checkWebGpu() {
  const state = $('#gpu-state')
  if (!navigator.gpu) {
    state.textContent = 'Unavailable in this browser'
    state.classList.add('warning')
    return
  }
  try {
    const adapter = await navigator.gpu.requestAdapter()
    state.textContent = adapter ? (adapter.info?.description || 'Adapter ready') : 'No adapter found'
    if (!adapter) state.classList.add('warning')
  } catch (error) {
    state.textContent = 'Adapter unavailable'
    state.classList.add('warning')
  }
}

$('#model-file').addEventListener('change', (event) => {
  const file = event.target.files[0]
  if (!file) return
  if (modelUrl.startsWith('blob:')) URL.revokeObjectURL(modelUrl)
  modelUrl = URL.createObjectURL(file)
  $('#model-url').value = ''
  $('#model-label').textContent = file.name
})

$('#model-url').addEventListener('input', (event) => {
  modelUrl = event.target.value.trim()
  $('#model-label').textContent = modelUrl ? 'Hosted model URL selected' : 'Choose an ONNX model'
})

$('#input-file').addEventListener('change', async (event) => {
  const file = event.target.files[0]
  if (!file) return
  try {
    const content = await file.text()
    const values = file.name.toLowerCase().endsWith('.json')
      ? flattenJson(JSON.parse(content))
      : content.split(/[\s,;]+/).filter(Boolean).map(Number)
    if (values.length !== 40 * 54 || values.some((value) => !Number.isFinite(value))) {
      throw new Error('Expected exactly 2,160 finite numbers (40 frames × 54 features).')
    }
    input = values
    $('#input-state').textContent = `${file.name} loaded · 40 × 54`
  } catch (error) {
    $('#input-state').textContent = error.message
    $('#input-state').classList.add('warning')
  }
})

function flattenJson(value) {
  if (!Array.isArray(value)) throw new Error('JSON must contain a nested numeric array.')
  const flattened = value.flat(Infinity)
  if (flattened.some((item) => typeof item !== 'number')) throw new Error('JSON values must all be numbers.')
  return flattened
}

$('#sample-button').addEventListener('click', () => {
  input = makeNeutralInput()
  $('#input-file').value = ''
  $('#input-state').textContent = 'Neutral sample loaded · 40 × 54'
  $('#input-state').classList.remove('warning')
})

runButton.addEventListener('click', async () => {
  if (!modelUrl) {
    status.textContent = 'Select an ONNX model first'
    return
  }
  if (!navigator.gpu) {
    status.textContent = 'This browser does not expose WebGPU'
    return
  }
  runButton.disabled = true
  status.textContent = 'Loading graph and running on WebGPU…'
  const start = performance.now()
  try {
    result = await infer(modelUrl, input, 'webgpu')
    if (result.length !== 152) throw new Error(`Unexpected model output size: ${result.length}`)
    renderResults(result, performance.now() - start)
    status.textContent = 'Inference complete'
  } catch (error) {
    status.textContent = `Inference failed: ${error.message}`
  } finally {
    runButton.disabled = false
  }
})

function renderResults(values, elapsed) {
  const groups = [
    ['ROOT ORIENTATION', 6, '6D rotation'],
    ['BODY POSE', 126, '21 joints × 6D'],
    ['SWIVEL', 8, 'cos / sin × 4 limbs'],
    ['ANKLE + TOE', 12, '4 vectors × xyz'],
  ]
  let offset = 0
  const cards = groups.map(([title, size, detail]) => {
    const data = values.slice(offset, offset + size)
    offset += size
    return `<article class="output-card"><div class="output-top"><span>${title}</span><span>${size}</span></div><div class="output-value">${data.slice(0, 3).map((v) => Number(v).toFixed(3)).join('<br>')}</div><small>${detail}</small><button class="copy-button" data-copy="${title}">COPY ARRAY ↗</button></article>`
  }).join('')
  $('#result-content').className = 'result-grid'
  $('#result-content').innerHTML = `<div class="result-summary"><span>INFERENCE TIME</span><strong>${elapsed.toFixed(1)}<small> ms</small></strong><button class="button secondary" id="download-result">DOWNLOAD JSON ↓</button></div>${cards}`
  $('#download-result').addEventListener('click', () => {
    const payload = { root_orientation: values.slice(0, 6), body_pose: values.slice(6, 132), swivel: values.slice(132, 140), ankle: values.slice(140, 152) }
    const anchor = document.createElement('a')
    anchor.href = URL.createObjectURL(new Blob([JSON.stringify(payload, null, 2)], { type: 'application/json' }))
    anchor.download = 'manikin-s-prediction.json'
    anchor.click()
    URL.revokeObjectURL(anchor.href)
  })
  document.querySelectorAll('[data-copy]').forEach((button) => button.addEventListener('click', async () => {
    const name = button.dataset.copy
    const section = groups.findIndex(([title]) => title === name)
    const startAt = [0, 6, 132, 140][section]
    await navigator.clipboard.writeText(JSON.stringify(values.slice(startAt, startAt + groups[section][1])))
    button.textContent = 'COPIED ✓'
  }))
}

checkWebGpu()
