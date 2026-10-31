final Map<String, String> _memory = {};

String? storageRead(String key) => _memory[key];

void storageWrite(String key, String value) => _memory[key] = value;

void storageRemove(String key) => _memory.remove(key);

List<String> storageKeys() => _memory.keys.toList();
