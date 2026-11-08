///|
/// ABI v1 takes one bounded replica count and returns 0 for valid, 1 for invalid.
/// This guest has no I/O and imports no host capabilities.
pub fn abi_version() -> Int32 {
  1
}

///|
pub fn validate(replicas : Int32) -> Int32 {
  if replicas >= 0 && replicas <= 100 {
    0
  } else {
    1
  }
}
