# Reaper Clip Exporter

Script Lua para preparar clips de audio en REAPER mediante **Dynamic Split, fades y regiones numeradas**. Pensado para agilizar tareas repetitivas al organizar efectos de sonido, variaciones y otros clips para un posterior renderizado.

**Archivo:** `joseisaudio_clipExporter.lua`

> Esta versión prepara los ítems y crea regiones. No renderiza ni exporta archivos de audio automáticamente.

## Funciones

- Abre la ventana nativa de **Dynamic Split** para configurar y previsualizar los cortes.
- Aplica fades de entrada y salida a los ítems seleccionados.
- Permite ajustar cada fade entre **0 y 2000 ms** mediante deslizadores.
- Ofrece siete opciones de forma para cada fade.
- Crea regiones opcionales con un nombre base y numeración automática: `SFX_01`, `SFX_02`, etc.
- Agrupa la aplicación de fades y la creación de regiones en una operación de deshacer.

## Requisitos

- REAPER con soporte para ReaScript Lua.
- El archivo `joseisaudio_clipExporter.lua`.

El script utiliza las API nativas de REAPER y su interfaz gráfica `gfx`. No requiere SWS, ReaPack, ReaImGui ni una instalación independiente de Lua.

## Instalación

1. Descarga `joseisaudio_clipExporter.lua` y guárdalo en una ubicación permanente.
2. En REAPER, abre **Actions → Show action list…**.
3. En la sección **Main**, utiliza **ReaScript → Load…** para cargar el archivo.
4. Selecciona el script en la lista de acciones y presiona **Run**.

Puedes asignarle un atajo de teclado desde la lista de acciones.

## Uso

### 1. Preparar y dividir los ítems

1. Selecciona los ítems de audio que deseas procesar.
2. Ejecuta el script.
3. Presiona **OPEN DYNAMIC SPLIT**.
4. Ajusta las opciones de Dynamic Split y revisa la previsualización de los cortes.
5. Ejecuta la división en esa ventana y regresa al script.

La configuración y la ejecución del recorte o la división se realizan dentro de Dynamic Split. El script abre la herramienta; no configura sus parámetros ni confirma automáticamente el resultado.

### 2. Configurar los fades

Selecciona una forma para **Fade in shape** y otra para **Fade out shape**. Ajusta sus duraciones con los deslizadores.

| Control | Valor inicial | Rango |
| --- | --- | --- |
| Fade in duration | 50 ms | 0–2000 ms |
| Fade out duration | 50 ms | 0–2000 ms |
| Forma de entrada y salida | Linear | Siete opciones |

Las etiquetas mostradas por el script son: **Linear, Fast Start, Fast End, S-Curve, Bezier, Logarithmic y Exponential**.

### 3. Crear regiones y aplicar

1. Activa **Create regions after Dynamic Split** si deseas crear regiones.
2. Escribe un nombre en **Base region name**, por ejemplo `Footstep_Concrete`.
3. Verifica que estén seleccionados los ítems que quieres procesar.
4. Presiona **APPLY FADES / REGIONS**.

Para tres ítems con comienzos distintos, el nombre del ejemplo produce:

```text
Footstep_Concrete_01
Footstep_Concrete_02
Footstep_Concrete_03
```

Cada región comienza en la posición del ítem y termina al final de su duración. El mensaje inferior indica cuántos ítems se procesaron y cuántas regiones se crearon.

También puedes usar **APPLY FADES / REGIONS** directamente sobre clips ya editados, sin abrir Dynamic Split.

### 4. Renderizar

Para obtener archivos de audio, utiliza después las herramientas de renderizado de REAPER y configura allí las regiones, las fuentes de audio y los ajustes de salida que necesites. Este script no configura el renderizado ni la Region Render Matrix.

## Comportamiento y limitaciones

- **Selección actual:** el botón de aplicación procesa los ítems seleccionados en ese momento. No conserva la selección inicial al abrir Dynamic Split.
- **Fades existentes:** al aplicar, se sobrescriben las duraciones y formas de los fades manuales de los ítems seleccionados. No hay una opción para omitir este paso.
- **Ítems simultáneos:** si varios ítems comienzan a menos de 0,0001 segundos entre sí, se crea una sola región para ese inicio. Su duración corresponde al primer ítem procesado, no necesariamente al más largo.
- **Ejecuciones repetidas:** la numeración comienza en `01` en cada aplicación. No se revisan las regiones existentes, por lo que volver a aplicar puede crear nombres y regiones repetidos.
- **Nombres:** un nombre base vacío o compuesto solo por espacios impide crear regiones. El campo admite caracteres ASCII imprimibles, hasta 80 caracteres; no admite tildes ni otros caracteres Unicode.
- **Ajustes temporales:** las preferencias vuelven a sus valores iniciales al cerrar y ejecutar de nuevo el script.
- **Edición de nombres:** el campo permite escribir al final y borrar con Backspace. Enter termina la edición y Esc cierra la ventana.
- **Deshacer:** los fades y las regiones de cada aplicación forman un bloque de deshacer. La operación realizada en Dynamic Split se gestiona por separado.

## Solución de problemas

| Situación | Qué revisar |
| --- | --- |
| Dynamic Split no se abre desde el script | Selecciona al menos un ítem antes de presionar el botón. |
| Aparece “No items are selected after Dynamic Split.” | Selecciona los clips resultantes y vuelve a aplicar. El mensaje también puede aparecer aunque no hayas usado Dynamic Split. |
| No se crean regiones | Comprueba que la casilla esté activa y que el nombre base no esté vacío. |
| Hay menos regiones que ítems seleccionados | Revisa si varios ítems comparten el mismo comienzo. |
| No aparecen archivos de audio exportados | Realiza el renderizado por separado en REAPER. |

## Acerca de esta documentación

Este README describe el comportamiento implementado en el archivo adjunto. No establece una versión mínima verificada de REAPER ni certifica compatibilidad probada por sistema operativo.
