# Manual de Usuario — PrediGeo

## Vista 3D del relieve

PrediGeo permite visualizar en 3D el relieve del terreno recorrido durante una
medición, sin necesidad de conexión a internet.

### Cómo se genera la superficie

1. Captura los puntos de la medición (cada punto incluye latitud, longitud y
   altitud GPS).
2. En la sección de relieve, pulsa el botón **3D** para alternar desde la
   vista plana (2D) a la vista 3D.
3. La aplicación triangula los puntos capturados (TIN) y dibuja la malla
   resultante con colores por altura.
4. Puedes rotar la malla arrastrando con un dedo, acercar/alejar con
   pellizco y mover con dos dedos. El botón de refrescar restablece la vista.

### Control de exageración vertical

Los botones **1x, 2x, 5x, 10x** ajustan la exageración vertical para hacer
visible el relieve en terrenos casi planos. El valor actual se muestra en
pantalla como "Exageración vertical: Nx".

### Limitaciones de precisión

- La altitud del GPS es **aproximada**: tiene menor precisión que la posición
  horizontal.
- La superficie 3D es una representación aproximada y no sustituye un
  levantamiento topográfico.
- La aplicación muestra siempre el aviso:
  *"Representación aproximada: la altitud del GPS tiene menor precisión que la
  horizontal"*.

### Funcionamiento sin internet

La vista 3D se calcula y renderiza completamente en el dispositivo: no
requiere conexión, mapas base ni claves de API. Está disponible en la captura
y en el detalle de una medición guardada (siempre que existan puntos con
altitud).