#!/usr/bin/env python3
"""Export a MANIKIN-S checkpoint to ONNX.

The exported graph accepts input shaped (batch, 40, 54) and returns
root orientation, body pose, swivel values, and ankle/foot vectors.
"""

import argparse
from pathlib import Path

import torch
import yaml

from networks.manikin_s import ManikinNet


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--config", required=True, help="MANIKIN-S options YAML")
    parser.add_argument("--checkpoint", required=True, help="trained .pth checkpoint")
    parser.add_argument("--output", required=True, help="output .onnx path")
    parser.add_argument("--opset", type=int, default=17)
    args = parser.parse_args()

    with open(args.config, encoding="utf-8") as f:
        opt = yaml.safe_load(f)
    if opt.get("model") != "manikin_s":
        parser.error("config must specify model: manikin_s")

    net_opt = opt["netG"]
    net = ManikinNet(
        input_dim=net_opt["input_dim"],
        num_layer=net_opt["num_layer"],
        embed_dim=net_opt["embed_dim"],
        nhead=net_opt["nhead"],
        rotation_keep_joints=net_opt["rotation_keep_joints"],
        dropout=net_opt.get("dropout", 0.1),
    )
    checkpoint = torch.load(args.checkpoint, map_location="cpu", weights_only=True)
    state_dict = checkpoint.get("params", checkpoint)
    net.load_state_dict(state_dict, strict=True)
    net.eval()

    dummy = torch.zeros(1, 40, net_opt["input_dim"], dtype=torch.float32)
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)
    torch.onnx.export(
        net,
        dummy,
        str(output),
        input_names=["input"],
        output_names=["root_orientation", "body_pose", "swivel", "ankle"],
        dynamic_axes={
            "input": {0: "batch"},
            "root_orientation": {0: "batch"},
            "body_pose": {0: "batch"},
            "swivel": {0: "batch"},
            "ankle": {0: "batch"},
        },
        opset_version=args.opset,
        dynamo=False,
    )
    print(f"Exported ONNX model to {output}")


if __name__ == "__main__":
    main()
