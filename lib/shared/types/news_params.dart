class NewsParams {
  final int page;
  final String? buildingId;

  const NewsParams({
    this.page = 1,
    this.buildingId,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NewsParams &&
          runtimeType == other.runtimeType &&
          page == other.page &&
          buildingId == other.buildingId;

  @override
  int get hashCode => page.hashCode ^ buildingId.hashCode;
}
