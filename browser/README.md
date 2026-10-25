# MANIKIN-S Browser

ブラウザ上でMANIKIN-SのONNXモデルを実行するアプリです。MoonBitの
`OJII3/onnxruntime_web` バインディングからONNX Runtime Webを呼び出し、WebGPU
Execution Providerを選択します。入力特徴量は学習時と同じ40フレーム×54要素です。

## 準備

MANIKIN-Sの学習済みチェックポイントを用意し、ONNXへ変換します。

```bash
python tools/export_manikin_s_onnx.py \
  --config options/manikin_s_amass.yaml \
  --checkpoint model_zoo/manikin_s_amass.pth \
  --output browser/public/manikin_s.onnx
```

チェックポイントはREADMEのEvaluationにあるGoogle Driveから取得します。アプリからONNXファイルを選択するか、公開URLを入力してください。

## Development

リポジトリルートでNix開発シェルに入り、依存を復元します。

```bash
nix develop
cd browser
moon -C ../moonbit update
moon -C ../moonbit build --target js --release
corepack pnpm@9.15.9 install --frozen-lockfile
corepack pnpm@9.15.9 dev
```

CSVはカンマ、空白、改行のいずれかで区切った2,160個の数値を受け付けます。JSONは数値配列を受け付け、`40×54`にflattenして読み込みます。出力はroot orientation (6)、body pose (126)、swivel (8)、ankle (12)です。

WebGPUは対応ブラウザとGPUが必要です。デモ用neutral sampleは形式確認用で、実際のトラッカー記録ではありません。
