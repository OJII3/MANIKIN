# MANIKIN model zoo

| file | model | eval set | config |
|---|---|---|---|
| `manikin_s_amass.pth` | MANIKIN-S | mixed | `options/manikin_s_amass.yaml` |
| `manikin_s_cross_cmu.pth` | MANIKIN-S | hold out CMU | `options/manikin_s_cross_cmu.yaml` |
| `manikin_s_cross_bml.pth` | MANIKIN-S | hold out BML | `options/manikin_s_cross_bml.yaml` |
| `manikin_s_cross_hdm05.pth` | MANIKIN-S | hold out HDM05 | `options/manikin_s_cross_hdm05.yaml` |
| `manikin_l_amass.pth` | MANIKIN-L | mixed | `options/manikin_l_amass_eval_online.yaml --benchmark amass_mixed` |
| `manikin_l_cross_cmu.pth` | MANIKIN-L | hold out CMU | `options/manikin_l_amass_eval_online.yaml --benchmark cross_cmu` |
| `manikin_l_cross_bml.pth` | MANIKIN-L | hold out BML | `options/manikin_l_amass_eval_online.yaml --benchmark cross_bml` |
| `manikin_l_cross_hdm05.pth` | MANIKIN-L | hold out HDM05 | `options/manikin_l_amass_eval_online.yaml --benchmark cross_hdm05` |

MANIKIN-S: `python main_test.py -opt options/manikin_s_cross_cmu.yaml --checkpoint model_zoo/manikin_s_cross_cmu.pth --gpu 0`
MANIKIN-L: `python main_test.py -opt options/manikin_l_amass_eval_online.yaml --checkpoint model_zoo/manikin_l_amass.pth --gpu 0 --benchmark amass_mixed`
MANIKIN-LN: same with `options/manikin_l_amass_eval_s2s.yaml`.

## Export MANIKIN-S to ONNX

With PyTorch and ONNX installed, export a MANIKIN-S checkpoint with:

```bash
python tools/export_manikin_s_onnx.py \
  --config options/manikin_s_amass.yaml \
  --checkpoint model_zoo/manikin_s_amass.pth \
  --output model_zoo/manikin_s_amass.onnx
```

Choose the matching `manikin_s_*.yaml` config and checkpoint for other evaluation sets. The ONNX input is
`(batch, 40, 54)`; the batch dimension is dynamic. The four outputs are root orientation, body pose, swivel
values, and ankle/foot vectors. This exports the MANIKIN-S neural network; preprocessing and analytic IK remain
outside the ONNX graph.
