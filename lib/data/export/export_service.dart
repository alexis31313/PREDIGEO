import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/measurement.dart';
import '../../domain/entities/measurement_enums.dart';
import '../../domain/entities/geo_point.dart';
import 'export_exception.dart';

class ExportService {
  String _escaparCSV(String valor) {
    if (valor.contains(',') || valor.contains('"') || valor.contains('\n')) {
      return '"${valor.replaceAll('"', '""')}"';
    }
    return valor;
  }

  Future<Directory> _obtenerDirectorio() async {
    try {
      return await getApplicationDocumentsDirectory();
    } catch (e) {
      throw ExportException('No se pudo obtener el directorio de documentos: $e');
    }
  }

  Future<String> exportToCSV(Measurement measurement, List<GeoPoint> points) async {
    try {
      final directorio = await _obtenerDirectorio();
      final archivo = File(p.join(directorio.path, 'medicion_${measurement.id}.csv'));

      final buffer = StringBuffer();
      buffer.writeln('id,nombre,tipo,area_m2,perimetro_m,distancia_m,modo,categoria,fecha');
      buffer.writeln('${measurement.id},${_escaparCSV(measurement.name)},${measurement.type.value},'
          '${measurement.areaM2?.toStringAsFixed(2) ?? ''},'
          '${measurement.perimeterM?.toStringAsFixed(2) ?? ''},'
          '${measurement.distanceM?.toStringAsFixed(2) ?? ''},'
          '${measurement.mode.value},${_escaparCSV(measurement.category?.value ?? '')},'
          '${measurement.createdAt.toIso8601String()}');

      await archivo.writeAsString(buffer.toString());
      return archivo.path;
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al exportar a CSV: $e');
    }
  }

  Future<String> exportPointsToCSV(Measurement measurement, List<GeoPoint> points) async {
    try {
      final directorio = await _obtenerDirectorio();
      final archivo = File(p.join(directorio.path, 'puntos_${measurement.id}.csv'));

      final buffer = StringBuffer();
      buffer.writeln('measurement_id,seq,latitud,longitud,altitud,precision,timestamp');

      for (var i = 0; i < points.length; i++) {
        final punto = points[i];
        buffer.writeln('${measurement.id},$i,${punto.latitude},${punto.longitude},'
            '${punto.altitude.toStringAsFixed(2)},${punto.accuracy.toStringAsFixed(2)},${punto.timestamp.toIso8601String()}');
      }

      await archivo.writeAsString(buffer.toString());
      return archivo.path;
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al exportar puntos a CSV: $e');
    }
  }

  Future<String> exportToGeoJSON(Measurement measurement, List<GeoPoint> points) async {
    try {
      final directorio = await _obtenerDirectorio();
      final archivo = File(p.join(directorio.path, 'medicion_${measurement.id}.geojson'));

      final coordenadas = points
          .map((punto) => '[${punto.longitude}, ${punto.latitude}, ${punto.altitude}]')
          .toList();

      final buffer = StringBuffer();
      buffer.writeln('{');
      buffer.writeln('  "type": "FeatureCollection",');
      buffer.writeln('  "features": [');
      buffer.writeln('    {');
      buffer.writeln('      "type": "Feature",');
      buffer.writeln('      "properties": {');
      buffer.writeln('        "name": "${_escaparJSON(measurement.name)}",');
      buffer.writeln('        "type": "${measurement.type.value}",');
      buffer.writeln('        "area_m2": ${measurement.areaM2 ?? 'null'},');
      buffer.writeln('        "perimeter_m": ${measurement.perimeterM ?? 'null'},');
      buffer.writeln('        "distance_m": ${measurement.distanceM ?? 'null'},');
      buffer.writeln('        "mode": "${measurement.mode.value}",');
      buffer.writeln('        "category": "${_escaparJSON(measurement.category?.value ?? '')}",');
      buffer.writeln('        "created_at": "${measurement.createdAt.toIso8601String()}"');
      buffer.writeln('      },');
      buffer.writeln('      "geometry": {');

      if (measurement.type == MeasurementType.area) {
        buffer.writeln('        "type": "Polygon",');
        buffer.writeln('        "coordinates": [');
        buffer.writeln('          [');
        for (var i = 0; i < coordenadas.length; i++) {
          final coma = i < coordenadas.length - 1 ? ',' : '';
          buffer.writeln('            ${coordenadas[i]}$coma');
        }
        if (coordenadas.isNotEmpty && coordenadas.first != coordenadas.last) {
          buffer.writeln('            ,${coordenadas.first}');
        }
        buffer.writeln('          ]');
        buffer.writeln('        ]');
      } else {
        buffer.writeln('        "type": "LineString",');
        buffer.writeln('        "coordinates": [');
        for (var i = 0; i < coordenadas.length; i++) {
          final coma = i < coordenadas.length - 1 ? ',' : '';
          buffer.writeln('          ${coordenadas[i]}$coma');
        }
        buffer.writeln('        ]');
      }

      buffer.writeln('      }');
      buffer.writeln('    }');
      buffer.writeln('  ]');
      buffer.writeln('}');

      await archivo.writeAsString(buffer.toString());
      return archivo.path;
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al exportar a GeoJSON: $e');
    }
  }

  Future<String> exportToKML(Measurement measurement, List<GeoPoint> points) async {
    try {
      final directorio = await _obtenerDirectorio();
      final archivo = File(p.join(directorio.path, 'medicion_${measurement.id}.kml'));

      final coordenadasKML = points
          .map((punto) => '${punto.longitude},${punto.latitude},${punto.altitude}')
          .join(' ');

      final descripcion = 'Tipo: ${measurement.type.value}\n'
          'Modo: ${measurement.mode.value}\n'
          'Categoría: ${measurement.category?.value ?? 'N/A'}\n'
          'Área: ${measurement.areaM2?.toStringAsFixed(2) ?? 'N/A'} m²\n'
          'Perímetro: ${measurement.perimeterM?.toStringAsFixed(2) ?? 'N/A'} m\n'
          'Distancia: ${measurement.distanceM?.toStringAsFixed(2) ?? 'N/A'} m\n'
          'Fecha: ${measurement.createdAt.toIso8601String()}';

      final buffer = StringBuffer();
      buffer.writeln('<?xml version="1.0" encoding="UTF-8"?>');
      buffer.writeln('<kml xmlns="http://www.opengis.net/kml/2.2">');
      buffer.writeln('  <Document>');
      buffer.writeln('    <name>${_escaparXML(measurement.name)}</name>');
      buffer.writeln('    <Placemark>');
      buffer.writeln('      <name>${_escaparXML(measurement.name)}</name>');
      buffer.writeln('      <description>${_escaparXML(descripcion)}</description>');

      if (measurement.type == MeasurementType.area) {
        buffer.writeln('      <Polygon>');
        buffer.writeln('        <outerBoundaryIs>');
        buffer.writeln('          <LinearRing>');
        buffer.writeln('            <coordinates>$coordenadasKML</coordinates>');
        buffer.writeln('          </LinearRing>');
        buffer.writeln('        </outerBoundaryIs>');
        buffer.writeln('      </Polygon>');
      } else {
        buffer.writeln('      <LineString>');
        buffer.writeln('        <coordinates>$coordenadasKML</coordinates>');
        buffer.writeln('      </LineString>');
      }

      buffer.writeln('    </Placemark>');
      buffer.writeln('  </Document>');
      buffer.writeln('</kml>');

      await archivo.writeAsString(buffer.toString());
      return archivo.path;
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al exportar a KML: $e');
    }
  }

  Future<String> exportMultipleToCSV(List<Measurement> measurements) async {
    try {
      final directorio = await _obtenerDirectorio();
      final archivo = File(p.join(directorio.path, 'mediciones_multiple_${DateTime.now().millisecondsSinceEpoch}.csv'));

      final buffer = StringBuffer();
      buffer.writeln('id,nombre,tipo,area_m2,perimetro_m,distancia_m,modo,categoria,fecha');

      for (final medicion in measurements) {
        buffer.writeln('${medicion.id},${_escaparCSV(medicion.name)},${medicion.type.value},'
            '${medicion.areaM2?.toStringAsFixed(2) ?? ''},'
            '${medicion.perimeterM?.toStringAsFixed(2) ?? ''},'
            '${medicion.distanceM?.toStringAsFixed(2) ?? ''},'
            '${medicion.mode.value},${_escaparCSV(medicion.category?.value ?? '')},'
            '${medicion.createdAt.toIso8601String()}');
      }

      await archivo.writeAsString(buffer.toString());
      return archivo.path;
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al exportar múltiples mediciones a CSV: $e');
    }
  }

  Future<void> shareFile(String filePath) async {
    try {
      final archivo = File(filePath);
      if (!await archivo.exists()) {
        throw ExportException('El archivo no existe: $filePath');
      }
      await Share.shareXFiles([XFile(filePath)]);
    } on ExportException {
      rethrow;
    } catch (e) {
      throw ExportException('Error al compartir el archivo: $e');
    }
  }

  String _escaparJSON(String valor) {
    return valor
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\t', '\\t');
  }

  String _escaparXML(String valor) {
    return valor
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
