///|
/// Decode a typed spec view without discarding unknown resource fields.
/// Keep the original Resource for writes, preserving metadata and unknown data.
pub fn[T : @json.FromJson] Resource::spec_as(
  self : Resource,
) -> T raise @json.JsonDecodeError {
  @json.from_json(field(self.json(), "spec"))
}
