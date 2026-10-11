# Pruebas en modo avión — PrediGeo

Este documento describe cómo verificar que el flujo completo de medición de
PrediGeo funciona **sin conexión a internet** (offline-first), tal como lo exige
el requisito RNF-01.

## 1. Objetivo

Comprobar que la captura de puntos, el cálculo de área/perímetro/distancia, la
visualización del relieve y el guardado local operan íntegramente en el
dispositivo, sin depender de la red.

## 2. Preparación del dispositivo

1. Instale la aplicación en un teléfono Android.
2. Active el **modo avión** (Ajustes → Conexiones → Modo avión).
3. Active únicamente el **GPS** (la ubicación funciona sin datos móviles).
4. Verifique que no hay ningún tipo de red (Wi-Fi ni datos móviles).

## 3. Procedimiento de prueba

1. Abra la aplicación y pulse **Nueva Medición**.
2. Compruebe que aparece el banner **"Modo Sin Conexión"**.
3. Seleccione el tipo de medición (**Área** o **Trayecto**).
4. Ubíquese en el terreno abierto. Espere a que el indicador de señal muestre
   una precisión aceptable (idealmente ≤ 5 m).
5. Pulse **Capturar punto**. Se promedian varias muestras y el punto se añade a
   la lista. Repita hasta cerrar el polígono (mínimo 3 puntos en Área, 2 en
   Trayecto).
6. Verifique que el **Resultado** muestra área (en m² y hectáreas) o distancia,
   y la precisión media.
7. Con dos o más puntos, confirme que se dibujan el **perfil de altitud** y la
   **vista de relieve**, y que la leyenda muestra el rango de altitudes.
8. Escriba un nombre, seleccione la categoría de terreno y añada
   observaciones.
9. Pulse **Guardar medición** y confirme el mensaje *"Medición guardada
   localmente"*.
10. Abra el **Historial** y compruebe que la medición aparece con sus datos.
11. Cierre la aplicación por completo y vuelva a abrirla: la medición sigue en
    el historial (persistencia local en SQLite).

## 4. Resultado esperado

- Todas las funciones anteriores operan sin conexión.
- No aparece ningún error de red ni pantalla en blanco.
- Los datos persisten entre reinicios de la aplicación.
- Las mediciones guardadas en modo avión quedan registradas con modalidad
  `offline`.

## 5. Casos límite a verificar

| Caso | Resultado esperado |
| --- | --- |
| Captura con precisión superior al umbral (p. ej. 25 m) | El punto se descarta y se informa al usuario. |
| Captura sin señal suficiente | Se muestra un mensaje de muestras insuficientes. |
| Guardar sin nombre | El botón permanece deshabilitado. |
| Área con menos de 3 puntos | No se calcula el área y se indica qué falta. |
| Rotar el dispositivo durante la captura | La sesión de medición no se pierde. |

## 6. Notas

- El umbral de precisión y el número de muestras por punto se configuran a
  través de `captureSettingsProvider` (valores por defecto: 10 muestras y 20 m).
- La pantalla de medición mantiene la pantalla encendida durante la captura
  mediante `wakelock_plus`.
