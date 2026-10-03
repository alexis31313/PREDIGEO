// Proveedor de Riverpod para la configuración de filtros
// aplicados a las mediciones y coordenadas.

import 'package:flutter_riverpod/flutter_riverpod.dart';

class FilterConfig {
  final String? typeFilter;
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minArea;
  final double? maxArea;
  final String searchQuery;

  const FilterConfig({
    this.typeFilter,
    this.startDate,
    this.endDate,
    this.minArea,
    this.maxArea,
    this.searchQuery = '',
  });

  FilterConfig copyWith({
    String? typeFilter,
    DateTime? startDate,
    DateTime? endDate,
    double? minArea,
    double? maxArea,
    String? searchQuery,
  }) {
    return FilterConfig(
      typeFilter: typeFilter ?? this.typeFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      minArea: minArea ?? this.minArea,
      maxArea: maxArea ?? this.maxArea,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  bool get hasActiveFilters =>
      typeFilter != null ||
      startDate != null ||
      endDate != null ||
      minArea != null ||
      maxArea != null ||
      searchQuery.isNotEmpty;
}

class FilterNotifier extends StateNotifier<FilterConfig> {
  FilterNotifier() : super(const FilterConfig());

  void setTypeFilter(String? type) {
    state = state.copyWith(typeFilter: type);
  }

  void setDateRange(DateTime? start, DateTime? end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setAreaRange(double? min, double? max) {
    state = state.copyWith(minArea: min, maxArea: max);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearAll() {
    state = const FilterConfig();
  }
}

final filterConfigProvider =
    StateNotifierProvider<FilterNotifier, FilterConfig>((ref) {
  return FilterNotifier();
});
