# Respuestas sugeridas para "Informacion_requerida_PrediGeo.docx"
## (Generadas a partir del código fuente de PrediGeo)

---

### I1 — Nombre de la empresa u organizaci��n receptora
**Sugerencia de respuesta:**
> La pasant��a se desarroll�� en el Semillero DigitalLab de la Universidad de
> Putumayo (UniPutumayo), programa de Tecnolog��a en Desarrollo de Software.
> El Semillero DigitalLab tiene como misi��n proponer soluciones tecnol��gicas
> para el contexto regional (Putumayo). La pasant��a se relaciona con el
> programa acadǸmico porque el proyecto PrediGeo es un desarrollo de software
> m��vil (Flutter/Android) que aplica conocimientos de ingenier��a de software,
> procesamiento de se��ales GPS, bases de datos y visualizaci��n geoespacial.

---

### E1 — Actividad econ��mica o misi��n institucional
**Sugerencia de respuesta:**
> Semillero DigitalLab: propone soluciones tecnol��gicas para el contexto
> regional (Putumayo), incluyendo aplicaciones m��viles para captura y anǭlisis
> de datos geoespaciales en campo.

---

### E2 — Estructura de la organizaci��n
**Sugerencia de respuesta:**
> Semillero de investigaci��n DigitalLab, adscrito al programa de Tecnolog��a
> en Desarrollo de Software de la Universidad de Putumayo. Trabaja bajo la
> direcci��n del asesor Jhon Alexander Gomez. No se cuenta con organigrama
> formal; el equipo de la pasant��a estuvo conformado por los dos estudiantes y
> el asesor.

---

### E3 — �?rea o dependencia donde se desarroll�� el trabajo
**Sugerencia de respuesta:**
> Semillero DigitalLab — desarrollo de software m��vil (Flutter/Android) para
> medici��n de terrenos y evaluaci��n de precisi��n GPS.

---

### E4 — Nombre y cargo del tutor o supervisor
**Sugerencia de respuesta:**
> Jhon Alexander Gomez — Asesor de la pasant��a / director del proyecto.

---

### O1 — Objetivos
**Sugerencia de respuesta:**
> Se mantuvieron los objetivos general y espec��ficos de la propuesta. El
> desarrollo result�� en la aplicaci��n PrediGeo, que cumple:
> 1. Captura de puntos GPS en campo (manual y automresultCode).
> 2. Cǭlculo local de ǭrea (Gauss/shoelace) y distancia (Haversine).
> 3. Modo conectado (mapa OpenStreetMap) y sin conexi��n (relieve local).
> 4. Historial persistente en SQLite con exportaci��n CSV.
> 5. Evaluaci��n de precisi��n (error absoluto, porcentual, RMSE).
> 6. Vista 3D del relieve generada localmente desde los puntos capturados.

---

### AC2 — Tecnolog��as efectivamente usadas
**Sugerencia de respuesta (copiar tal cual):**

| Componente | Tecnolog��a / Versi��n |
|---|---|
| Lenguaje | Dart (SDK >=3.3.0 <4.0.0) |
| Framework | Flutter (>=3.19.0) |
| Gesti��n de estado | Flutter Riverpod ^2.4.9 |
| Navegaci��n | go_router ^14.2.0 |
| GPS / ubicaci��n | geolocator ^13.0.1, permission_handler ^11.3.0 |
| Base de datos | sqflite ^2.3.3, path ^1.9.0, path_provider ^2.1.4 |
| Mapas | flutter_map ^8.3.2 + latlong2 ^0.10.0 (OpenStreetMap, offline) |
| Conectividad | connectivity_plus ^6.0.5 |
| Exportaci��n | share_plus ^10.0.0, csv ^6.0.0 |
| Internacionalizaci��n | intl ^0.19.0 |
| Preferencias | shared_preferences ^2.3.2 |
| Wake lock | wakelock_plus ^1.2.8 |
| Control de versiones | Git (rama Alex) |
| Pruebas | flutter_test + mocktail ^1.0.4 |
| Lints | flutter_lints ^4.0.0 |

> Nota: la propuesta mencionaba Google Maps, pero el stack real usa
> flutter_map + OpenStreetMap (offline-first). Actualizar en el documento.

---

### AC4 — Metodolog��a
**Sugerencia de respuesta:**
> Se utiliz�� Scrum con sprints de aproximadamente dos semanas, segǧn la
> propuesta. El desarrollo se organiz�� en etapas incrementales (captura GPS,
> cálculo de ǭrea/distancia, modo conectado/sin conexi��n, historial,
> evaluaci��n de precisi��n, vista 3D). Se realizaron reuniones peri��dicas con
> el asesor Jhon Alexander Gomez para revisi��n de avances. Las fechas exactas
> de cada sprint y reuni��n deben completarse con los registros del equipo.

---

### R1 — Estado final del producto
**Sugerencia de respuesta:**
> - Versi��n de la app: 1.0.0+1.
> - M��dulos terminados: captura GPS (manual y automresultCode), cálculo de
>   ǭrea (Gauss/shoelace), distancia/per��metro (Haversine), modo conectado
>   (mapa OpenStreetMap) y sin conexi��n (relieve local), historial persistente
>   en SQLite, exportaci��n CSV, vista 3D del relieve (TIN/Delaunay local),
>   onboarding, evaluaci��n de precisi��n, GPS debug.
> - Repositorio: Git, rama Alex.
> - APK debug probada en OPPO A40 (CPH2669, Android 14, arm64).
> - Pruebas: 220/220 pasan.

---

### R6 — Manual de usuario y manual del programador
**Sugerencia de respuesta:**
> - Manual de usuario: `docs/manual_usuario.md` (incluye secci��n de vista 3D).
> - Manual del programador / arquitectura: `docs/arquitectura.md` (actualizado
>   con secci��n 8 sobre la vista 3D: generaci��n de superficie, limitaciones de
>   precisi��n vertical y funcionamiento sin internet).

---

### O1 — Objetivos
**Sugerencia de respuesta:**
> Se mantuvieron los objetivos general y espec��ficos de la propuesta. El
> desarrollo result�� en la aplicaci��n PrediGeo, que cumple: captura de puntos
> GPS en campo, cálculo local de ǭrea y distancia, modo conectado y sin
> conexi��n, historial en SQLite, evaluaci��n de precisi��n (error absoluto,
> porcentual, RMSE) y vista 3D del relieve generada localmente.

---

### P1 — T��tulo definitivo
**Sugerencia de respuesta:**
> "PrediGeo: Evaluaci��n de precisi��n geoespacial en aplicaci��n m��vil Android
> para medici��n de terrenos con GPS" (opci��n (a) de la propuesta, secci��n 1).
> Confirmar con el asesor.

---

### P5 — Nombres de los autores
**Sugerencia de respuesta:**
> Luis Alejandro Paz Acero y Steve Alexander Calvache Mart��nez (con tilde en
> Mart��nez, segǧn la graf��a oficial).

---

### P6 — Nombre del asesor
**Sugerencia de respuesta:**
> Jhon Alexander Gomez (segǧn la propuesta). Confirmar nombre completo.

---

### I1 — Organizaci��n receptora
**Sugerencia de respuesta:**
> Semillero DigitalLab, Universidad de Putumayo (UniPutumayo), programa de
> Tecnolog��a en Desarrollo de Software. La pasant��a se relaciona con el
> programa porque PrediGeo es un desarrollo de software m��vil (Flutter/Android)
> que aplica conocimientos de ingenier��a de software, procesamiento de se��ales
> GPS, bases de datos y visualizaci��n geoespacial.

---

## Preguntas que NO puedo responder desde el código
Estas requieren informaci��n de la pasant��a/gesti��n:

- **P2, P3, P4**: T��tulo acadǸmico, facultad, a��o de presentaci��n.
- **M1, M2**: Modalidad final, fechas reales, total de horas.
- **E2, E3, E4**: Estructura/organigrama, ǭrea de trabajo, tutor/supervisor.
- **AC1**: Tabla de actividades ejecutadas (fechas reales, evidencias).
- **AC3**: Levantamiento de requerimientos (entrevistas, observaciones).
- **AC5**: Reparto de roles entre los dos estudiantes.
- **R2-R5, R7**: Pruebas de campo, resultados de precisi��n, derechos de autor, capturas.
- **AP1, CO1, RE1**: Aprendizajes, hallazgos, recomendaciones.
- **RF1**: Datos completos de referencias bibliogrǭficas.
- **AN1**: Soportes (consentimientos, certificaciones, acta de cesi��n).

---

## Nota importante para el documento
La propuesta mencionaba Google Maps, pero el c��digo real usa **flutter_map +
OpenStreetMap** (offline-first). Actualiza I1, E1 y AC2 en consecuencia.
