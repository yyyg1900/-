void assertSuccess(bool value) {
  assert(value);
}

bool get debugging {
  bool ret = false;
  assert(ret = true);
  return ret;
}
