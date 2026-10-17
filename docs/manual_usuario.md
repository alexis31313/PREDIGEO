# Manual de Usuario - PrediGeo

## Aplicación Móvil de Medición GNSS

---

## Índice

1. [Introducción](#1-introducción)
2. [Requisitos de Instalación](#2-requisitos-de-instalación)
3. [Cómo Tomar una Medición](#3-cómo-tomar-una-medición)
4. [Cómo Ver el Historial](#4-cómo-ver-el-historial)
5. [Cómo Exportar Datos](#5-cómo-exportar-datos)
6. [Cómo Evaluar la Precisión](#6-cómo-evaluar-la-precisión)
7. [Solución de Problemas](#7-solución-de-problemas)
8. [Preguntas Frecuentes](#8-preguntas-frecuentes)

---

## 1. Introducción

PrediGeo es una aplicación móvil diseñada para medir áreas y distancias utilizando el sistema GNSS (GPS) de su dispositivo. La aplicación está especialmente pensada para trabajar en zonas rurales y urbanas, incluso sin conexión a Internet.

### Características Principales

- Medición de áreas mediante polígonos sobre el terreno
- Medición de distancias recorridas (trayectos)
- Funcionamiento 100% sin conexión (offline)
- Procesamiento de señal GPS para mejorar la precisión
- Historial completo de mediciones
- Exportación de datos para análisis posterior
- Evaluación de precisión con datos de campo

---

## 2. Requisitos de Instalación

### Requisitos Mínimos del Sistema

| Requisito | Especificación |
|-----------|---------------|
| Sistema Operativo | Android 7.0 (Nougat) o superior |
| Versión mínima SDK | API 24 (Android 7.0) |
| Procesador | 1.2 GHz o superior |
| Memoria RAM | 2 GB mínimo |
| Almacenamiento | 50 MB de espacio libre |
| GPS | Chip GNSS/GPS integrado |
| Conectividad | No requerida (funciona sin Internet) |

### Instalación

1. Obtenga el archivo APK de PrediGeo desde la fuente oficial.
2. En su dispositivo Android, vaya a **Ajustes > Seguridad**.
3. Active la opción **"Fuentes desconocidas"** o **"Instalar desde fuentes desconocidas"**.
4. Localice el archivo APK en su administrador de archivos.
5. Toque el archivo y seleccione **"Instalar"**.
6. Espere a que finalice la instalación.
7. Abra la aplicación desde el menú de aplicaciones.

> **Nota:** Si ya tiene una versión anterior instalada, puede actualizar directamente sin desinstalar; sus datos se conservarán.

---

## 3. Cómo Tomar una Medición

### Paso a Paso

#### Paso 1: Preparación

- Salga al exterior con vista despejada del cielo.
- Asegúrese de que el GPS esté activado en su dispositivo.
- Espere unos segundos a que el dispositivo adquiera señal de satélites.

#### Paso 2: Iniciar la Medición

1. Abra la aplicación PrediGeo.
2. En la pantalla de inicio, seleccione el tipo de medición:
   - **Área:** Para medir la superficie de un terreno (polígono).
   - **Trayecto:** Para medir la distancia recorrida.
3. Presione el botón **"Iniciar"**.

#### Paso 3: Capturar Puntos

- Camine por el perímetro del terreno (para Área) o por el camino a medir (para Trayecto).
- La aplicación captura automáticamente sus coordenadas a intervalos regulares.
- El **indicador de señal GPS** en pantalla muestra la calidad de la recepción:
  - Verde: Señal buena (alta precisión)
  - Amarillo: Señal regular
  - Rojo: Señal deficiente (se recomienda esperar)

#### Paso 4: Finalizar la Medición

1. Una vez completado el recorrido, presione **"Detener"**.
2. La aplicación calculará automáticamente el área o la distancia.
3. Asigne un **nombre** a la medición para identificarla.
4. Seleccione la **categoría del terreno**:
   - Rural abierto
   - Rural con vegetación
   - Urbano
5. Seleccione el **modo de captura** utilizado:
   - En línea (con Internet)
   - Sin conexión (offline)
6. Agregue **notas** si lo desea.
7. Presione **"Guardar"**.

### Consejos para Mejorar la Precisión

- Camine a velocidad constante y pausada.
- Mantenga el dispositivo en posición vertical.
- Evite zonas con edificios altos o árboles muy densos.
- Espere a que el indicador de señal esté en verde antes de comenzar.
- Realice la medición en horas del día con buena visibilidad satelital.

---

## 4. Cómo Ver el Historial

1. Desde la pantalla de inicio, toque **"Historial"**.
2. Se mostrará una lista de todas las mediciones guardadas, ordenadas de más reciente a más antigua.
3. Cada elemento del historial muestra:
   - Nombre de la medición
   - Tipo (Área o Trayecto)
   - Valor calculado
   - Fecha de captura
   - Precisión promedio del GPS
4. Toque cualquier medición para ver el **detalle completo**, incluyendo:
   - Todos los puntos capturados
   - Perímetro y distancia total
   - Perfil de elevación (cuando está disponible)
   - Modo y categoría asignados

### Filtros del Historial

- **Por tipo:** Muestra solo Áreas o solo Trayectos.
- **Por categoría:** Filtra por Rural abierto, Rural con vegetación o Urbano.
- **Por modo:** Filtra por En línea o Sin conexión.

### Eliminar una Medición

1. En el historial, deslice el elemento hacia la izquierda (o mantenga presionado).
2. Seleccione **"Eliminar"**.
3. Confirme la eliminación.

---

## 5. Cómo Exportar Datos

La exportación permite guardar sus mediciones en formato compatible con hojas de cálculo y software de análisis estadístico.

### Pasos para Exportar

1. Vaya a la pantalla de **Historial**.
2. Presione el botón **"Exportar"** (icono de compartir).
3. Seleccione el formato de exportación:
   - **CSV** (Valores separados por comas): Compatible con Excel, Google Sheets, etc.
4. Si lo desea, aplique filtros antes de exportar (por categoría, modo, rango de fechas).
5. Presione **"Exportar"**.
6. Elija el destino del archivo exportado:
   - Guardar en el dispositivo
   - Enviar por correo electrónico
   - Compartir con otras aplicaciones

### Contenido del Archivo Exportado

El archivo CSV incluye las siguientes columnas:

| Columna | Descripción |
|---------|-------------|
| id_identificador | ID único de la medición |
| nombre | Nombre asignado |
| tipo | Área o Trayecto |
| area_m2 | Área calculada en metros cuadrados |
| perimeter_m | Perímetro del polígono en metros |
| distance_m | Distancia total del trayecto |
| n_puntos | Número de puntos capturados |
| modo | Modo de captura (online/offline) |
| category | Categoría de terreno |
| avg_accuracy_m | Precisión promedio del GPS en metros |
| fecha | Fecha y hora de la medición (ISO8601) |
| notes | Notas adicionales |

---

## 6. Cómo Evaluar la Precisión

La función de evaluación de precisión permite comparar las mediciones realizadas con PrediGeo contra valores de referencia confiables.

### Configurar una Evaluación de Campo

1. Vaya a la pantalla **"Evaluación"**.
2. Seleccione la medición que desea evaluar.
3. Ingrese el **valor de referencia** obtenido de una fuente confiable (topografía, GPS RTK, etc.).
4. Seleccione el **tipo de referencia**:
   - Área (m²)
   - Distancia (m)
5. Indique la **fuente del valor de referencia**.
6. Registre las **condiciones ambientales** durante la medición.
7. Presione **"Guardar evaluación"**.

### Ver los Resultados de Precisión

En la pantalla de Evaluación puede consultar:

- **Error absoluto:** Diferencia directa entre el valor medido y el valor de referencia.
- **Error porcentual:** Error expresado como porcentaje del valor de referencia.
- **RMSE:** Raíz del error cuadrático medio, útil para evaluar la consistencia de múltiples mediciones.
- **Estadísticas por categoría:** Resumen agrupado por tipo de terreno.
- **Estadísticas por modo:** Comparación entre modo En línea y Sin conexión.

### Interpretación de Resultados

| Rango de Error Porcentual | Clasificación |
|---------------------------|---------------|
| 0% - 2% | Excelente |
| 2% - 5% | Bueno |
| 5% - 10% | Aceptable |
| > 10% | Se recomienda repetición |

---

## 7. Solución de Problemas

### Problema: No hay señal GPS

**Posibles causas y soluciones:**

| Causa | Solución |
|-------|----------|
| GPS desactivado | Active el GPS en Ajustes > Ubicación |
| Interiores | Salga al exterior |
| Sin vista al cielo | Aléjese de edificios altos |
| Problema temporal | Reinicie la aplicación o el dispositivo |
| Modo de ubicación "Ahorro de batería" | Cambie a "Alta precisión" |

### Problema: La precisión es muy baja (indicador rojo)

- Espere 1-2 minutos para que el GPS se estabilice.
- Asegúrese de tener vista despejada del cielo.
- Verifique que la fecha y hora del dispositivo sean correctas.
- Reinicie el GPS apagando y encendiendo la ubicación.

### Problema: La aplicación se cierra inesperadamente

- Verifique que tenga suficiente espacio de almacenamiento.
- Cierre otras aplicaciones que consuma memoria RAM.
- Reinstale la aplicación (sus datos se conservan en la base de datos local).
- Actualice a la versión más reciente de la aplicación.

### Problema: Los valores medidos parecen incorrectos

- Verifique que caminó por todo el perímetro sin saltar secciones.
- Asegúrese de haber capturado al menos 3 puntos para un polígono.
- Repita la medición y compare los resultados.
- Considere las condiciones ambientales que pudieron afectar la señal.

### Problema: No puedo exportar datos

- Verifique que tenga una aplicación compatible instalada (lector de CSV).
- Revise los permisos de almacenamiento de la aplicación.
- Asegúrese de tener mediciones guardadas antes de exportar.
- Intente guardar el archivo en una ubicación diferente.

---

## 8. Preguntas Frecuentes

### P: ¿PrediGeo necesita Internet para funcionar?

**R:** No. La aplicación funciona completamente sin conexión a Internet. Sin embargo, para mejorar la precisión inicial del GPS, se recomienda tener conexión al inicio de cada sesión.

### P: ¿Qué tan preciso es PrediGeo?

**R:** La precisión depende de varios factores: la calidad del chip GPS de su dispositivo, las condiciones ambientales y la vista del cielo. En condiciones óptimas, la precisión típica es de 3 a 8 metros.

### P: ¿Se pueden medir todo tipo de terrenos?

**R:** Sí, la aplicación permite clasificar el terreno en tres categorías: rural abierto, rural con vegetación y urbano. Esto permite analizar cómo afecta el entorno a la precisión.

### P: ¿Dónde se guardan mis mediciones?

**R:** Todas las mediciones se guardan localmente en su dispositivo. No se envían a ningún servidor externo.

### P: ¿Puedo usar los datos en mi propio análisis?

**R:** Sí. Puede exportar todas sus mediciones en formato CSV y usarlas en Excel, R, Python o cualquier otro software de análisis.

### P: ¿La aplicación consume mucha batería?

**R:** El uso del GPS es el principal consumo de energía. Se recomienda tener la batería cargada al 100% antes de sesiones largas y evitar el uso de la pantalla con brillo máximo.

### P: ¿Qué hago si el medición es muy diferente a la esperada?

**R:** Realice una nueva medición en el mismo punto. Si la diferencia persiste, verifique las condiciones de señal GPS y considere repetir la medición en otro momento del día.

### P: ¿Puedo editar una medición ya guardada?

**R:** Las mediciones no se pueden editar una vez guardadas para preservar la integridad de los datos. Si necesita corregirla, elimine la medición y realice una nueva.

---

## 9. Primer Uso: Bienvenida, Consentimiento y Permisos

### 9.1 Pantalla de bienvenida (Onboarding)

1. Al abrir PrediGeo por primera vez verás 3 páginas: qué hace PrediGeo, que funciona sin conexión y cómo obtener buena precisión GPS.
2. Desliza o pulsa **Siguiente** para avanzar. Los puntos inferiores indican en qué página estás.
3. Pulsa **Omitir** o **Empezar** en la última página para continuar. Solo se muestra la primera vez.

### 9.2 Consentimiento informado (Ley 1581 de 2012)

1. Lee el resumen de uso académico y confidencialidad (datos solo en tu teléfono, sin servidores externos).
2. Marca la casilla **"He leído y acepto el consentimiento informado"**.
3. El botón **Continuar** se habilita solo al aceptar. Púlsalo para seguir. La fecha de aceptación se guarda en el teléfono.

### 9.3 Permiso de ubicación

1. Lee por qué se necesita la ubicación precisa y que en modo sin conexión los datos no salen del teléfono.
2. Pulsa **Permitir ubicación precisa** para lanzar la solicitud del sistema.
3. Si el permiso queda denegado de forma permanente, aparece **Abrir ajustes del sistema**: úsalo para habilitarlo manualmente.

## 10. Ajustes

Desde la pantalla de inicio pulsa el icono de engranaje o la tarjeta **Ajustes**.

### 10.1 Modo de operación

- Elige **Sin conexión** (offline-first, por defecto) o **En línea**.
- La pantalla Nueva Medición muestra el modo activo. El selector que estaba temporalmente en Medición ahora vive aquí.

### 10.2 Muestras por punto (5 a 30)

- Mueve el deslizador para elegir cuántas lecturas GPS se promedian por punto (por defecto 10).
- `PointCaptureService` usa este valor en cada captura y muestra el progreso 0..1.

### 10.3 Umbral de precisión GPS (metros)

- Elige entre 3 y 50 m (por defecto 20 m). Las lecturas peores se descartan con `OutlierFilter`.
- Un umbral bajo exige mejor señal pero puede tardar más en capturar.

### 10.4 Unidad de área preferida (m², ha, fanegada)

- Elige cómo ver las áreas en resultados, historial y detalle (usa `AreaUnits`).
- Ejemplo con 10 000 m²: `10 000,00 m²`, `1,00 ha` o `1,56 fanegada`.

### 10.5 Tema (claro, oscuro, sistema)

- Elige el `ThemeMode` de la app. Se aplica de inmediato.

### 10.6 Acerca de

- Muestra la versión (con `package_info_plus`), el equipo (Steve Alexander Calvache Martinez y Luis Alejandro Paz Acero) y el asesor Jhon Alexander Gómez.

## Soporte Técnico

Si encuentra algún problema no cubierto en este manual, por favor contacte a los desarrolladores:

- **Correo:** [soporte@predigeo.com]
- **Repositorio:** [enlace al repositorio del proyecto]

---

*PrediGeo - Aplicación de Medición GNSS*  
*Universidad de Putumayo - 2026*
