///|
fn dns_label(value : String) -> Bool {
  fn alnum(c : Char) -> Bool {
    (c >= 'a' && c <= 'z') || (c >= '0' && c <= '9')
  }
  !value.is_empty() &&
  value.length() <= 63 &&
  alnum(value.get_char(0).unwrap()) &&
  alnum(value.get_char(value.length() - 1).unwrap()) &&
  value.all(c => alnum(c) || c == '-')
}

///|
/// Core API group is empty; named API groups are DNS subdomains.
pub fn api_group_valid(value : String) -> Bool {
  value.is_empty() ||
  (
    value.length() <= 253 &&
    value.split(".").all(label => dns_label(label.to_owned()))
  )
}

///|
pub fn ResourceType::validate(self : ResourceType) -> Unit raise OperatorError {
  let kind = self.gvk.kind
  fn alpha(c : Char) -> Bool {
    (c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_'
  }
  if !api_group_valid(self.gvk.group) ||
    !dns_label(self.gvk.version) ||
    !dns_label(self.plural) ||
    kind.is_empty() ||
    kind.length() > 63 ||
    !alpha(kind.get_char(0).unwrap()) ||
    !kind.all(c => alpha(c) || (c >= '0' && c <= '9')) {
    raise Invalid("invalid GVK or resource plural")
  }
}
