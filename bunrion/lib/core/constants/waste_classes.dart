class WasteClasses {
  static const names = <int, String>{
    0: '플라스틱류',
    1: '종이류',
    2: '음료수곽',
    3: '유리병류',
    4: '캔류',
    5: '비닐류',
    6: '스티로폼류',
  };

  static String nameOf(int id) => names[id] ?? '지원하지 않는 품목';
  static bool isSupported(int id) => names.containsKey(id);

  static int? idOf(String name) {
    final normalized = name.trim();
    for (final entry in names.entries) {
      if (entry.value == normalized) return entry.key;
    }
    return null;
  }
}
