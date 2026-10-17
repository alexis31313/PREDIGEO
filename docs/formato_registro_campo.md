# Formato de Registro de Campo - PrediGeo

## Documento de Recolección de Datos en Terreno

---

## 1. Propósito

Este documento define el formato estándar para el registro de mediciones de campo realizadas con la aplicación PrediGeo. Su objetivo es garantizar la consistencia y trazabilidad de los datos recolectados durante la evaluación de precisión del sistema GNSS.

---

## 2. Tabla de Registro

| Fecha | ID Medición | Valor Medido (m²/m) | Valor Referencia | Fuente | Categoría Terreno | Modo Captura | Condiciones Ambientales | Observaciones |
|-------|-------------|---------------------|------------------|--------|-------------------|--------------|-------------------------|---------------|
|       |             |                     |                  |        |                   |              |                         |               |

---

## 3. Definición de Columnas

| Columna | Descripción | Formato | Ejemplo |
|---------|-------------|---------|---------|
| Fecha | Fecha de la medición | DD/MM/AAAA | 15/03/2026 |
| ID Medición | Identificador único asignado por la app | Texto alfanumérico | PRED-001 |
| Valor Medido | Área en m² o distancia en m según tipo | Número decimal | 1523.45 |
| Valor Referencia | Valor de comparación confiable | Número decimal | 1500.00 |
| Fuente | Origen del valor de referencia | Texto | Topografía con GPS RTK |
| Categoría Terreno | Clasificación del terreno | Opción fija | Rural abierto / Rural con vegetación / Urbano |
| Modo Captura | Modo de conexión utilizado | Opción fija | En línea / Sin conexión |
| Condiciones Ambientales | Estado del entorno durante la medición | Texto | Despejado, viento leve, temperatura 28°C |
| Observaciones | Notas adicionales relevantes | Texto libre | Intermitencia de señal al inicio |

---

## 4. Datos de Ejemplo

### Ejemplo 1 - Medición Rural Abierta (Sin Conexión)

| Fecha | ID Medición | Valor Medido (m²/m) | Valor Referencia | Fuente | Categoría Terreno | Modo Captura | Condiciones Ambientales | Observaciones |
|-------|-------------|---------------------|------------------|--------|-------------------|--------------|-------------------------|---------------|
| 15/03/2026 | PRED-001 | 1523.45 | 1500.00 | Estación total | Rural abierto | Sin conexión | Despejado, 28°C, viento 5 km/h | Terreno plano, sin obstáculos |
| 15/03/2026 | PRED-002 | 1498.32 | 1500.00 | Estación total | Rural abierto | Sin conexión | Despejado, 29°C, viento 3 km/h | Segunda medición para consistencia |

### Ejemplo 2 - Medición Rural con Vegetación (En Línea)

| Fecha | ID Medición | Valor Medido (m²/m) | Valor Referencia | Fuente | Categoría Terreno | Modo Captura | Condiciones Ambientales | Observaciones |
|-------|-------------|---------------------|------------------|--------|-------------------|--------------|-------------------------|---------------|
| 16/03/2026 | PRED-003 | 2105.78 | 2080.00 | GPS RTK | Rural con vegetación | En línea | Nublado, 25°C, humedad 80% | Degradación señal por dosel arbóreo |
| 16/03/2026 | PRED-004 | 2078.11 | 2080.00 | GPS RTK | Rural con vegetación | En línea | Parcialmente nublado, 26°C | Se esperó estabilización GPS |

### Ejemplo 3 - Medición Urbana (En Línea)

| Fecha | ID Medición | Valor Medido (m²/m) | Valor Referencia | Fuente | Categoría Terreno | Modo Captura | Condiciones Ambientales | Observaciones |
|-------|-------------|---------------------|------------------|--------|-------------------|--------------|-------------------------|---------------|
| 17/03/2026 | PRED-005 | 456.23 | 450.00 | Levantamiento catastral | Urbano | En línea | Despejado, 30°C, tráfico moderado | Efecto multipathing cerca a edificios |
| 17/03/2026 | PRED-006 | 448.67 | 450.00 | Levantamiento catastral | Urbano | En línea | Despejado, 31°C | Se verificó con medición manual |

---

## 5. Instrucciones de Uso en Campo

### 5.1 Preparación

1. Verificar que la batería del dispositivo esté cargada al 100%.
2. Confirmar que la aplicación PrediGeo esté actualizada a la última versión.
3. Validar que el GPS del dispositivo esté activado y con señal adecuada.
4. Identificar el valor de referencia antes de realizar la medición.

### 5.2 Captura de Datos

1. Registrar la fecha y hora al inicio de cada medición.
2. Seleccionar el tipo de medición: Área (polígono) o Trayecto (distancia).
3. Clasificar el terreno según las tres categorías definidas.
4. Indicar el modo de captura (En línea o Sin conexión).
5. Realizar el recorrido del perímetro o trayecto de manera continua.
6. Esperar a que la aplicación confirme el número mínimo de puntos (3 para polígono).
7. Guardar la medición y registrar el valor mostrado.

### 5.3 Registro Complementario

1. Anotar las condiciones ambientales predominantes durante la medición.
2. Registrar cualquier observación relevante: obstáculos, interferencias, eventos.
3. Tomar fotografías del terreno como respaldo documental.
4. Verificar que el valor de referencia esté correctamente documentado con su fuente.

### 5.4 Controles de Calidad

- Mínimo 2 mediciones por punto de referencia en cada categoría de terreno.
- Registrar al menos 3 sesiones en cada modo de captura (En línea y Sin conexión).
- Verificar que no existan variaciones mayores al 10% entre mediciones repetidas.
- Documentar cualquier anomalía de GPS o pérdida de señal.

---

## 6. Referencias

- Manual de Usuario PrediGeo
- Manual de Programador PrediGeo
- Documento de evaluación de precisión (ver `evaluation_screen.dart`)

---

*Documento elaborado para el proyecto de investigación PrediGeo - Universidad de Putumayo*
