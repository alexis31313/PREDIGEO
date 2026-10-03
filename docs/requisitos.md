# Documento de Requisitos — PrediGeo

## 1. Introducción

PrediGeo es una aplicación móvil Flutter para la captura, procesamiento y análisis de datos GPS en tiempo real, orientada a la medición de áreas, distancias y perímetros de terrenos. La aplicación opera en modo offline-first y ofrece funcionalidades de filtrado de señal, visualización de perfiles de elevación y exportación de datos.

## 2. Requisitos Funcionales

### RF-01: Captura de coordenadas GPS

El sistema debe permitir la captura de coordenadas geográficas (latitud, longitud, altitud) mediante el sensor GPS del dispositivo. Cada punto capturado debe incluir:

- Latitud en grados decimales
- Longitud en grados decimales
- Altitud en metros sobre el nivel del mar
- Marca temporal de captura
- Indicador de precisión horizontal

### RF-02: Cálculo de área por fórmula de Gauss (shoelace)

El sistema debe calcular el área de un polígono definido por un conjunto de coordenadas GPS utilizando la fórmula de Gauss (también conocida como fórmula del área de Gauss o algoritmo shoelace). El cálculo debe:

- Aceptar un mínimo de 3 puntos
- Retornar el área en metros cuadrados
- Permitir la conversión a hectáreas y otras unidades
- Manejar polígonos cerrados automáticamente

### RF-03: Cálculo de distancia y perímetro con Haversine

El sistema debe calcular la distancia entre dos puntos geográficos y el perímetro total de un polígono utilizando la fórmula de Haversine. Los cálculos deben:

- Considerar la curvatura terrestre
- Retornar distancias en metros
- Sumar segmentos consecutivos para el perímetro
- Manejar distancias de hasta 20,000 km con precisión aceptable

### RF-04: Almacenamiento local en SQLite

El sistema debe almacenar todos los datos de medición en una base de datos SQLite local. La base de datos debe incluir tablas para:

- Mediciones (sesiones de captura)
- Puntos GPS individuales
- Polígonos y sus vértices
- Metadatos de precisión

### RF-05: Historial de mediciones con consulta y gestión

El sistema debe permitir al usuario:

- Listar todas las mediciones realizadas
- Consultar el detalle de una medición específica
- Eliminar mediciones anteriores
- Buscar mediciones por fecha o nombre
- Visualizar estadísticas generales

### RF-06: Exportación de datos en formato CSV

El sistema debe permitir la exportación de datos de medición en formato CSV. La exportación debe:

- Incluir todas las coordenadas del polígono
- Incluir metadatos (fecha, área calculada, perímetro)
- Permitir compartir el archivo por correo o aplicaciones externas
- Generar archivos compatibles con Excel y hojas de cálculo

### RF-07: Filtrado de señal GPS (filtro de Kalman)

El sistema debe implementar un filtro de Kalman para reducir el ruido de la señal GPS. El filtro debe:

- Suavizar las coordenadas capturadas en tiempo real
- Reducir la desviación estándar de las mediciones
- Ser configurable en cuanto a nivel de suavizado
- Operar en tiempo real sin retraso perceptible

### RF-08: Visualización de perfil de elevación

El sistema debe generar una gráfica del perfil de elevación basada en las coordenadas capturadas. La visualización debe:

- Mostrar altitud en función de la distancia acumulada
- Permitir zoom y desplazamiento
- Resaltar puntos de máxima y mínima elevación
- Mostrar estadísticas de desnivel

### RF-09: Evaluación de precisión

El sistema debe evaluar la precisión de las mediciones comparando con valores de referencia. Las métricas incluyen:

- Error absoluto en metros
- Error porcentual relativo al valor de referencia
- RMSE (Root Mean Square Error) del conjunto de puntos
- Indicador de calidad de la medición

### RF-10: Modo conectado con Google Maps

El sistema debe permitir la visualización de las mediciones sobre un mapa de Google Maps cuando hay conexión a internet. Esta funcionalidad debe:

- Mostrar el polígono sobre el mapa
- Permitir cambiar entre vista satelital y normal
- Mostrar marcadores en cada vértice
- Centrar la cámara en el área medida

### RF-11: Modo offline sin dependencia de internet

El sistema debe funcionar completamente sin conexión a internet. En modo offline:

- Todas las funcionalidades de captura y cálculo deben operar normalmente
- Los mapas deben mostrar una vista alternativa o mensaje informativo
- Los datos deben almacenarse localmente
- La exportación CSV debe funcionar sin conexión

### RF-12: Gestión de permisos de ubicación

El sistema debe gestionar adecuadamente los permisos de ubicación del dispositivo:

- Solicitar permisos al iniciar la aplicación
- Manejar casos de permisos denegados con mensajes explicativos
- Redirigir a configuración del sistema si es necesario
- Soportar permisos de ubicación en segundo plano cuando aplique

## 3. Requisitos No Funcionales

### RNF-01: Arquitectura offline-first

La aplicación debe seguir un patrón de arquitectura offline-first donde:

- La base de datos SQLite es la fuente primaria de datos
- Toda la lógica de negocio funciona sin conexión
- La sincronización con servicios en la nube es opcional
- La interfaz de usuario nunca depende de la conectividad

### RNF-02: Precisión GPS menor a 5 metros en área abierta

La aplicación debe alcanzar una precisión horizontal menor a 5 metros en condiciones de campo abierto:

- Utilizar el filtro de Kalman para mejorar la precisión
- Mostrar indicador de precisión en tiempo real
- Permitir recalibración manual
- Registrar la precisión de cada punto capturado

### RNF-03: Rendimiento — respuesta menor a 2 segundos

La aplicación debe garantizar tiempos de respuesta menores a 2 segundos para:

- Cálculo de área y perímetro
- Guardado de mediciones en SQLite
- Carga del historial de mediciones
- Generación de archivo CSV
- Inicio de la aplicación en estado frío

### RNF-04: Privacidad — cumplimiento Ley 1581 de 2012

La aplicación debe cumplir con la Ley 1581 de 2012 de protección de datos personales de Colombia:

- Los datos GPS se almacenan únicamente en el dispositivo
- No se transmiten datos personales a servidores externos sin consentimiento
- Se debe informar al usuario sobre el tratamiento de datos
- Se debe permitir la eliminación total de datos almacenados
- Se debe incluir política de privacidad accesible desde la aplicación

### RNF-05: Compatibilidad — Android 7.0+ (minSdk 24)

La aplicación debe ser compatible con:

- Android 7.0 Nougat (API level 24) como versión mínima
- Android 14 (API level 34) como versión objetivo
- Dispositivos con pantalla de 4.7 pulgadas o superiores
- Arquitecturas ARM y x86

### RNF-06: Interfaz en español

La interfaz de usuario debe estar completamente en español (Colombia):

- Todos los textos, mensajes y etiquetas en español
- Formato de números con separador de miles por punto y decimales por coma
- Fechas en formato DD/MM/AAAA
- Mensajes de error y confirmación en español
