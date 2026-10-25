fn assert_close(actual : Double, expected : Double) -> Unit raise Error {
  assert_true((actual - expected).abs() < 1.0e-9)
}

test "6D rotation conversion uses MANIKIN column convention" {
  let identity = @src.sixd_to_matrix([1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
  assert_eq(identity, [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0])
  assert_eq(@src.matrix_to_sixd(identity), [1.0, 0.0, 0.0, 0.0, 1.0, 0.0])
}

test "local rotations compose through the parent tree" {
  let quarter_turn_z = [0.0, -1.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0]
  let identity = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]
  let global = @src.local_to_global_rotations(
    [..quarter_turn_z, ..identity],
    [-1, 0],
  )
  assert_eq(global, [..quarter_turn_z, ..quarter_turn_z])
}

test "swivel geometry round trips a middle joint" {
  let base = [0.0, 0.0, 0.0]
  let end = [0.0, 0.0, 2.0]
  let vertical = [0.0, -1.0, 0.0]
  let angle = 0.7
  let mid = @src.swivel_to_mid(base, end, vertical, angle, 1.2, 1.2, 2.0)
  assert_close(@src.positions_to_swivel(base, mid, end, vertical), angle)
  assert_close((mid[0] * mid[0] + mid[1] * mid[1] + mid[2] * mid[2]).sqrt(), 1.2)
}

test "reduced rotations expand with identity defaults" {
  let identity = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0]
  let first = [0.0, 1.0, 0.0, -1.0, 0.0, 0.0]
  let second = [0.0, 0.0, 1.0, 0.0, 1.0, 0.0]
  let pose = @src.expand_body_rotations([..first, ..second], [1, 3], identity)
  assert_eq(pose[0:6], identity)
  assert_eq(pose[6:12], first)
  assert_eq(pose[18:24], second)
  assert_eq(pose[120:126], identity)
}

test "swivel and foot outputs decode to angles and world points" {
  let angles = @src.decode_swivel_angles([1.0, 0.0, -1.0, 0.0, 0.0, 1.0, 0.0, -1.0])
  assert_close(angles[0], 0.0)
  assert_close(angles[1], 1.5707963267948966)
  assert_close(angles[2], 3.141592653589793)
  assert_close(angles[3], -1.5707963267948966)

  let feet = @src.decode_foot_points(
    [1.0, 2.0, 3.0, -1.0, -2.0, -3.0, 0.1, 0.2, 0.3, -0.1, -0.2, -0.3],
    [10.0, 20.0, 30.0],
  )
  assert_eq(feet, [11.0, 22.0, 33.0, 9.0, 18.0, 27.0, 11.1, 22.2, 33.3, 8.9, 17.8, 26.7])
}

test "head alignment translation moves positions into world space" {
  let translation = @src.align_head_translation([1.0, 2.0, 3.0], [10.0, 20.0, 30.0])
  assert_eq(translation, [9.0, 18.0, 27.0])
  assert_eq(@src.translate_positions([0.0, 1.0, 2.0, 3.0, 4.0, 5.0], translation), [9.0, 19.0, 29.0, 12.0, 22.0, 32.0])
}
