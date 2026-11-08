///|
async test "bounded handle reads enforce exact EOF and overflow budgets" {
  let directory = "_build/credential-budget-fixtures"
  @fs.mkdir(directory, recursive=true, allow_exist=true)
  let path = directory + "/token"
  @fs.write_file(path, "12345678")
  assert_eq(read_bounded_file(path, 8), b"12345678")
  @fs.write_file(path, "123456789")
  assert_true(
    try read_bounded_file(path, 8) catch {
      @core.Capacity(_) => true
      _ => false
    } noraise {
      _ => false
    },
  )
  @fs.write_file(path, "rotated")
  assert_eq(read_bounded_file(path, 8), b"rotated")
}
