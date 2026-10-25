///| Normalize a 3D vector. A zero vector stays zero, matching torch.nn.functional.normalize.
fn normalize3(v : Array[Double]) -> Array[Double] {
  let length = (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt()
  if length == 0.0 {
    [0.0, 0.0, 0.0]
  } else {
    [v[0] / length, v[1] / length, v[2] / length]
  }
}

///|
fn dot3(a : Array[Double], b : Array[Double]) -> Double {
  a[0] * b[0] + a[1] * b[1] + a[2] * b[2]
}

///|
fn cross3(a : Array[Double], b : Array[Double]) -> Array[Double] {
  [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}

///|
fn clamp(value : Double, low : Double, high : Double) -> Double {
  if value < low {
    low
  } else if value > high {
    high
  } else {
    value
  }
}

///| Convert one MANIKIN 6D rotation (two column vectors) to a row-major 3x3 matrix.
///| The Gram-Schmidt convention matches utils_transform.sixd2matrot.
pub fn sixd_to_matrix(sixd : Array[Double]) -> Array[Double] {
  let b1 = normalize3([sixd[0], sixd[1], sixd[2]])
  let a2 = [sixd[3], sixd[4], sixd[5]]
  let projection = dot3(b1, a2)
  let b2 = normalize3([
    a2[0] - projection * b1[0],
    a2[1] - projection * b1[1],
    a2[2] - projection * b1[2],
  ])
  let b3 = cross3(b1, b2)
  [b1[0], b2[0], b3[0], b1[1], b2[1], b3[1], b1[2], b2[2], b3[2]]
}

///|
/// Convert a row-major 3x3 rotation matrix to MANIKIN's 6D column representation.
pub fn matrix_to_sixd(matrix : Array[Double]) -> Array[Double] {
  [matrix[0], matrix[3], matrix[6], matrix[1], matrix[4], matrix[7]]
}

///|
/// Convert per-joint local row-major rotations to global rotations along a parent tree.
///| `local` is concatenated Jx3x3 data and `parents[j]` is -1 for a root.
pub fn local_to_global_rotations(local_rotations : Array[Double], parents : Array[Int]) -> Array[Double] {
  let joint_count = parents.length()
  let global = Array::make(joint_count * 9, 0.0)
  let mut joint = 0
  while joint < joint_count {
    let parent = parents[joint]
    let local_offset = joint * 9
    if parent < 0 {
      let mut k = 0
      while k < 9 {
        global[local_offset + k] = local_rotations[local_offset + k]
        k = k + 1
      }
    } else {
      let parent_offset = parent * 9
      let mut row = 0
      while row < 3 {
        let mut col = 0
        while col < 3 {
          let mut value = 0.0
          let mut k = 0
          while k < 3 {
            value = value + global[parent_offset + row * 3 + k] * local_rotations[local_offset + k * 3 + col]
            k = k + 1
          }
          global[local_offset + row * 3 + col] = value
          col = col + 1
        }
        row = row + 1
      }
    }
    joint = joint + 1
  }
  global
}

///|
/// Reconstruct a limb's middle joint relative to its base from the swivel angle.
///| Distances are base-to-mid, mid-to-end, and base-to-end, in that order.
pub fn swivel_to_mid(
  base : Array[Double],
  end : Array[Double],
  vertical : Array[Double],
  swivel : Double,
  d1 : Double,
  d2 : Double,
  d3 : Double,
) -> Array[Double] {
  let cos_tmp = clamp((d1 * d1 + d2 * d2 - d3 * d3) / (2.0 * d1 * d2), -1.0 + 1.0e-6, 1.0 - 1.0e-6)
  let v3 = 3.141592653589793 - @math.acos(cos_tmp)
  let cos_alpha = clamp((d1 * d1 + d3 * d3 - d2 * d2) / (2.0 * d1 * d3), -1.0, 1.0)
  let sin_alpha = clamp(d2 * @math.sin(3.141592653589793 - v3) / d3, -1.0, 1.0)
  let axis = normalize3([end[0] - base[0], end[1] - base[1], end[2] - base[2]])
  let projection = dot3(vertical, axis)
  let u = normalize3([
    -vertical[0] + projection * axis[0],
    -vertical[1] + projection * axis[1],
    -vertical[2] + projection * axis[2],
  ])
  let v = cross3(u, axis)
  let axial = d1 * cos_alpha
  let radius = d1 * sin_alpha
  let c = @math.cos(swivel)
  let s = @math.sin(swivel)
  [
    axis[0] * axial + radius * (u[0] * c + v[0] * s),
    axis[1] * axial + radius * (u[1] * c + v[1] * s),
    axis[2] * axial + radius * (u[2] * c + v[2] * s),
  ]
}

///|
/// Recover the swivel angle from base, mid, end, and the limb-root reference vector.
pub fn positions_to_swivel(
  base : Array[Double],
  mid : Array[Double],
  end : Array[Double],
  vertical : Array[Double],
) -> Double {
  let base_mid = [mid[0] - base[0], mid[1] - base[1], mid[2] - base[2]]
  let base_end = [end[0] - base[0], end[1] - base[1], end[2] - base[2]]
  let mid_end = [end[0] - mid[0], end[1] - mid[1], end[2] - mid[2]]
  let d1 = (dot3(base_mid, base_mid)).sqrt()
  let d2 = (dot3(mid_end, mid_end)).sqrt()
  let d3 = (dot3(base_end, base_end)).sqrt()
  let cos_alpha = clamp((d1 * d1 + d3 * d3 - d2 * d2) / (2.0 * d1 * d3), -1.0, 1.0)
  let axis = normalize3(base_end)
  let projection = dot3(vertical, axis)
  let u0 = [
    -vertical[0] + projection * axis[0],
    -vertical[1] + projection * axis[1],
    -vertical[2] + projection * axis[2],
  ]
  let u = normalize3(u0)
  let v = cross3(u, axis)
  let c = [axis[0] * d1 * cos_alpha, axis[1] * d1 * cos_alpha, axis[2] * d1 * cos_alpha]
  let radial = [mid[0] - base[0] - c[0], mid[1] - base[1] - c[1], mid[2] - base[2] - c[2]]
  let k = normalize3(radial)
  @math.atan2(dot3(k, v), dot3(k, u))
}

///|
/// Expand MANIKIN-S's reduced joint rotations to the 21-joint 6D body pose.
///| `identity` is the six-value identity rotation, repeated for all body joints.
pub fn expand_body_rotations(
  raw_rotations : Array[Double],
  kept_slots : Array[Int],
  identity : Array[Double],
) -> Array[Double] {
  let pose = Array::make(21 * 6, 0.0)
  let mut joint = 0
  while joint < 21 {
    let mut axis = 0
    while axis < 6 {
      pose[joint * 6 + axis] = identity[axis]
      axis = axis + 1
    }
    joint = joint + 1
  }
  let mut slot = 0
  while slot < kept_slots.length() {
    let mut axis = 0
    while axis < 6 {
      pose[kept_slots[slot] * 6 + axis] = raw_rotations[slot * 6 + axis]
      axis = axis + 1
    }
    slot = slot + 1
  }
  pose
}

///|
/// Convert MANIKIN-S's [cos(4), sin(4)] head output to four swivel angles.
pub fn decode_swivel_angles(swivel_output : Array[Double]) -> Array[Double] {
  let angles = Array::make(4, 0.0)
  let mut limb = 0
  while limb < 4 {
    angles[limb] = @math.atan2(swivel_output[limb + 4], swivel_output[limb])
    limb = limb + 1
  }
  angles
}

///|
/// Convert predicted head-relative ankle positions and ankle-to-toe vectors to world points.
///| Output is [left ankle, right ankle, left toe, right toe], each as xyz.
pub fn decode_foot_points(ankle_output : Array[Double], head_world : Array[Double]) -> Array[Double] {
  let points = Array::make(12, 0.0)
  let mut foot = 0
  while foot < 2 {
    let ankle_offset = foot * 3
    let toe_offset = 6 + foot * 3
    let point_offset = foot * 3
    points[point_offset] = head_world[0] + ankle_output[ankle_offset]
    points[point_offset + 1] = head_world[1] + ankle_output[ankle_offset + 1]
    points[point_offset + 2] = head_world[2] + ankle_output[ankle_offset + 2]
    let toe_point_offset = 6 + foot * 3
    points[toe_point_offset] = points[point_offset] + ankle_output[toe_offset]
    points[toe_point_offset + 1] = points[point_offset + 1] + ankle_output[toe_offset + 1]
    points[toe_point_offset + 2] = points[point_offset + 2] + ankle_output[toe_offset + 2]
    foot = foot + 1
  }
  points
}

///|
/// Find translation that places the predicted head joint at the tracked world position.
pub fn align_head_translation(predicted_head : Array[Double], tracked_head : Array[Double]) -> Array[Double] {
  [tracked_head[0] - predicted_head[0], tracked_head[1] - predicted_head[1], tracked_head[2] - predicted_head[2]]
}

///|
/// Add a translation to concatenated xyz positions, returning a new array.
pub fn translate_positions(positions : Array[Double], translation : Array[Double]) -> Array[Double] {
  let translated = Array::make(positions.length(), 0.0)
  let mut i = 0
  while i + 2 < positions.length() {
    translated[i] = positions[i] + translation[0]
    translated[i + 1] = positions[i + 1] + translation[1]
    translated[i + 2] = positions[i + 2] + translation[2]
    i = i + 3
  }
  translated
}

fn main {
  println("MANIKIN-S MoonBit inference utilities")
}
