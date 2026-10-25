# MANIKIN-S MoonBit utilities

`src/main.mbt` は MANIKIN-S の推論で使う配列ベースの数値処理を提供します。Python の
`utils/utils_transform.py` と `networks/swivel.py` のうち、後処理に使う部分を移植しています。

含まれる処理:

- 6D 回転表現と 3x3 回転行列の変換
- 関節ごとの局所回転から大域回転への合成
- cos/sin 形式の swivel 出力の角度化と、肘・膝位置の再構成
- MANIKIN-S の縮約回転出力の 21 関節 pose への展開
- 頭に対する平行移動、および足首・つま先の world 座標化

関数は `Array[Double]` を受け取り、ベクトルは xyz、行列は row-major で表します。
6D 回転は MANIKIN/Python 実装と同じく、回転行列の最初の 2 列を連結した形式です。

このパッケージだけでは推論パイプラインは完結しません。ニューラルネットワーク実行には
別途 ONNX Runtime 等が必要で、SMPL+H のボディモデルを使う forward kinematics と、FK を
含む `solve_limb_angles` の全移植も未実装です。

## Development environment

From the repository root, enter the Nix development shell:

```bash
nix develop
```

Then run `moon check` from this directory.
