///|
/// Read at most limit+1 bytes from one opened handle. A changing path or file
/// size cannot bypass the allocation budget. Projected-token symlinks work.
async fn read_bounded_file(path : String, limit : Int32) -> Bytes {
  if limit <= 0 || limit > 1048576 {
    raise @core.Invalid("invalid credential file budget")
  }
  @async.with_timeout(10000, () => {
    let file = @fs.open(path, mode=ReadOnly)
    defer file.close()
    if file.kind() != Regular {
      raise @core.Invalid("configuration must be a regular file")
    }
    let output = Buffer()
    for ;; {
      match
        file.read_some(max_len=Int32::min(8192, limit - output.length() + 1)) {
        None => break
        Some(bytes) => {
          if bytes.length() > limit - output.length() {
            raise @core.Capacity("credential file byte limit")
          }
          output.write_bytes(bytes)
        }
      }
    }
    output.to_bytes()
  })
}
