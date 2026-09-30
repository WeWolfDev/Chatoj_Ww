# CHATOJ — Selva y jade

## Ejecutar

1. Extrae todo el ZIP.
2. En **Godot 4.7.2**, importa el archivo **project.godot** de esta carpeta.
3. Espera la importación de imágenes y audio y presiona **F6** sobre MainMenu.tscn o **F5** para iniciar el proyecto. Elige Jugar.

No requiere plugins ni descargas de recursos. Es el proyecto editable, no un ejecutable exportado.

## Qué cambió

- Ocho identidades visuales: protagonista, guardián, soldado jaguar, Wayob, sombra, Kakasbal, Camazotz y murciélago.
- Protagonista con caminata de seis cuadros en cuatro direcciones. Los enemigos usan vistas direccionales con movimiento secundario programado; el combate conserva sus tiempos y efectos existentes.
- Mapa reconstruido con un TileSet real de 64 × 64 y dos capas editables: Suelo y SelvaYLimites. Conserva la disposición general del original: templo al oeste, aldea central, granja al norte, cenote al noreste, senderos y caverna al sureste. Se compactó a 5376 × 3584 para adecuar las distancias a la velocidad del personaje.
- Vegetación, estelas, chozas, pirámides y antorchas con iluminación; colisiones en bosque, agua y edificios.
- Enemigos distribuidos por zonas y santuario de guardado visible en la aldea.
- Audio, acciones, interfaz y lógica del proyecto original conservados. Corregidas las rutas de inicio para una importación limpia y la animación de curación que faltaba.

## Controles

| Acción | Tecla |
|---|---|
| Movimiento | WASD |
| Correr | Shift |
| Esquivar | Espacio |
| Atacar | Clic izquierdo |
| Escudo | Clic derecho |
| Lanzar daga | E |
| Curarse | R |
| Alternar vista amplia del mapa | M |
| Volver al menú | Esc |

La vista amplia no pausa el combate. El checkpoint conserva el comportamiento original: dura durante la sesión, no es una partida guardada en disco.

## Editar

Abre **Scenes/mapaPrueba.tscn**. Las capas Suelo y SelvaYLimites pueden pintarse desde el editor de TileMap. El tileset y los nuevos sprites están en **assets/Rediseno/**. Los diseños fueron generados con la herramienta integrada de imágenes; los prompts se incluyen en **ARTE_GENERADO.txt**. Se conservan también los recursos originales.

## Verificación

Probado en Godot 4.7.2: carga del menú y partida, ocho personajes, 4704 celdas de terreno, movimiento, ataque, escudo, curación, daño a enemigos, colisión del bosque y activación del checkpoint. VISTA_ALDEA.png y VISTA_MAPA.png son capturas reales de la partida. No se realizó una partida completa de balance o victoria contra todos los jefes.
