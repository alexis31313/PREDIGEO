import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../core/utils/formatters.dart';
import '../providers/measurement_repository_provider.dart';
import '../providers/settings_provider.dart';
import 'measurement_detail_screen.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _deleteMode = false;
  final Set<int> _selectedIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleDeleteMode() {
    setState(() {
      _deleteMode = !_deleteMode;
      if (!_deleteMode) _selectedIds.clear();
    });
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar mediciones'),
        content: Text(
          '¿Está seguro de eliminar $count medición${count == 1 ? '' : 'es'}? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final notifier = ref.read(measurementHistoryActionsProvider.notifier);
      for (final id in _selectedIds) {
        await notifier.remove(id);
      }
      setState(() {
        _selectedIds.clear();
        _deleteMode = false;
      });
    }
  }

  List<Measurement> _sortMeasurements(
    List<Measurement> measurements,
    _SortOption sort,
  ) {
    final sorted = List<Measurement>.from(measurements);
    switch (sort) {
      case _SortOption.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case _SortOption.largest:
        sorted.sort((a, b) {
          final areaA = a.areaM2 ?? 0;
          final areaB = b.areaM2 ?? 0;
          return areaB.compareTo(areaA);
        });
        break;
      case _SortOption.smallest:
        sorted.sort((a, b) {
          final areaA = a.areaM2 ?? double.maxFinite;
          final areaB = b.areaM2 ?? double.maxFinite;
          return areaA.compareTo(areaB);
        });
        break;
    }
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(measurementHistoryProvider);
    final searchAsync = ref.watch(
      measurementSearchProvider(_searchController.text),
    );
    final filter = ref.watch(measurementFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial'),
        actions: [
          IconButton(
            icon: Icon(
              filter.hasActiveFilters
                  ? Icons.filter_alt
                  : Icons.filter_alt_outlined,
            ),
            onPressed: () => _showFilterSheet(context, filter),
            tooltip: 'Filtros',
          ),
          PopupMenuButton<_SortOption>(
            icon: const Icon(Icons.sort),
            tooltip: 'Ordenar',
            onSelected: (option) {},
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _SortOption.newest,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_downward, size: 18),
                    const SizedBox(width: 8),
                    const Text('Más reciente'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortOption.oldest,
                child: Row(
                  children: [
                    const Icon(Icons.arrow_upward, size: 18),
                    const SizedBox(width: 8),
                    const Text('Más antigua'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortOption.largest,
                child: Row(
                  children: [
                    const Icon(Icons.photo_size_select_large, size: 18),
                    const SizedBox(width: 8),
                    const Text('Mayor área'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: _SortOption.smallest,
                child: Row(
                  children: [
                    const Icon(Icons.photo_size_select_small, size: 18),
                    const SizedBox(width: 8),
                    const Text('Menor área'),
                  ],
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              _deleteMode ? Icons.close : Icons.delete_outline,
            ),
            onPressed: _toggleDeleteMode,
            tooltip: _deleteMode ? 'Salir de eliminación' : 'Eliminar modo',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          _buildFilterChips(filter),
          if (_deleteMode && _selectedIds.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text('${_selectedIds.length} seleccionada(s)'),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _deleteSelected,
                    icon: const Icon(Icons.delete),
                    label: const Text('Eliminar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(measurementHistoryProvider);
                ref.invalidate(measurementSearchProvider);
              },
              child: _buildList(historyAsync, searchAsync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(MeasurementFilter filter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: const Text('Tipo: Todos'),
              selected: filter.type == null,
              onSelected: (_) {},
              avatar: const Icon(Icons.layers, size: 16),
            ),
          ),
          if (filter.type == null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Área'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setType(MeasurementType.area),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Distancia'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setType(MeasurementType.path),
              ),
            ),
          ],
          if (filter.mode == null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Manual'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setMode(MeasurementMode.online),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Automático'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setMode(MeasurementMode.offline),
              ),
            ),
          ],
          if (filter.category == null) ...[
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Rural'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setCategory(MeasurementCategory.ruralOpen),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Urbano'),
                selected: false,
                onSelected: (_) => ref
                    .read(measurementFilterProvider.notifier)
                    .setCategory(MeasurementCategory.urban),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildList(
    AsyncValue<List<Measurement>> historyAsync,
    AsyncValue<List<Measurement>> searchAsync,
  ) {
    return searchAsync.when(
      data: (allMeasurements) {
        final query = _searchController.text.toLowerCase();
        var measurements = query.isEmpty
            ? allMeasurements
            : allMeasurements
                .where((m) => m.name.toLowerCase().contains(query))
                .toList();

        final filter = ref.read(measurementFilterProvider);
        if (filter.type != null) {
          measurements = measurements.where((m) => m.type == filter.type).toList();
        }
        if (filter.mode != null) {
          measurements = measurements.where((m) => m.mode == filter.mode).toList();
        }
        if (filter.category != null) {
          measurements =
              measurements.where((m) => m.category == filter.category).toList();
        }

        if (measurements.isEmpty) {
          return ListView(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay mediciones',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }

        return ListView.builder(
          itemCount: measurements.length,
          padding: const EdgeInsets.only(top: 8, bottom: 16),
          itemBuilder: (context, index) {
            final measurement = measurements[index];
            return _MeasurementCard(
              measurement: measurement,
              deleteMode: _deleteMode,
              selected: _selectedIds.contains(measurement.id),
              onTap: _deleteMode
                  ? () => _toggleSelection(measurement.id!)
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MeasurementDetailScreen(
                          measurementId: measurement.id!,
                        ),
                      ),
                    ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
              const SizedBox(height: 12),
              Text(
                'Error al cargar mediciones',
                style: TextStyle(color: Colors.red[700]),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => ref.invalidate(measurementSearchProvider),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, MeasurementFilter filter) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filtros',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Tipo',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: filter.type == null,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setType(null);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Área'),
                        selected: filter.type == MeasurementType.area,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setType(MeasurementType.area);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Distancia'),
                        selected: filter.type == MeasurementType.path,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setType(MeasurementType.path);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Modo',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todos'),
                        selected: filter.mode == null,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setMode(null);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Manual'),
                        selected: filter.mode == MeasurementMode.online,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setMode(MeasurementMode.online);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Automático'),
                        selected: filter.mode == MeasurementMode.offline,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setMode(MeasurementMode.offline);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text('Categoría',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('Todas'),
                        selected: filter.category == null,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setCategory(null);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Rural'),
                        selected: filter.category == MeasurementCategory.ruralOpen,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setCategory(MeasurementCategory.ruralOpen);
                          setSheetState(() {});
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Urbano'),
                        selected: filter.category == MeasurementCategory.urban,
                        onSelected: (_) {
                          ref
                              .read(measurementFilterProvider.notifier)
                              .setCategory(MeasurementCategory.urban);
                          setSheetState(() {});
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

enum _SortOption { newest, oldest, largest, smallest }

class _MeasurementCard extends ConsumerWidget {
  final Measurement measurement;
  final bool deleteMode;
  final bool selected;
  final VoidCallback onTap;

  const _MeasurementCard({
    required this.measurement,
    required this.deleteMode,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: selected ? 4 : 1,
      color: selected ? scheme.primaryContainer : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (deleteMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: selected,
                    onChanged: (_) => onTap(),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      measurement.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      Formatters.formatDate(measurement.createdAt),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (measurement.areaM2 != null) ...[
                          Icon(Icons.square_foot, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            ref.watch(
                              formattedAreaProvider(measurement.areaM2!),
                            ),
                            style: const TextStyle(fontSize: 13),
                          ),
                          const SizedBox(width: 16),
                        ],
                        if (measurement.distanceM != null) ...[
                          Icon(Icons.straighten, size: 16, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(
                            Formatters.formatDistance(measurement.distanceM!),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Chip(
                          label: Text(
                            measurement.type.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: primaryColor.withValues(alpha: 0.1),
                        ),
                        Chip(
                          label: Text(
                            measurement.mode.label,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: scheme.tertiaryContainer,
                        ),
                        if (measurement.category != null)
                          Chip(
                            label: Text(
                              measurement.category!.label,
                              style: const TextStyle(fontSize: 11),
                            ),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: scheme.secondaryContainer,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
