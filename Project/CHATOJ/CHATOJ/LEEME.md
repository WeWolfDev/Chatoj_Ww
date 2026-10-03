# CHATOJ optimizado

## Abrir y jugar

1. Extrae el ZIP completo en una carpeta nueva.
2. Importa `project.godot` en **Godot 4.7.2**.
3. Espera la primera importación y pulsa **F5**. En el menú, elige **Jugar**.

Se conserva como principal el mapa que abría el botón Jugar del proyecto original. No requiere Ziva, complementos, Python ni descargas de recursos. El motor de Godot no se incluye en el ZIP.

La primera apertura vuelve a crear `.godot/`; es normal que la carpeta crezca después. Esa caché no se debe incluir al compartir el proyecto.

## Dónde editar

| Contenido | Ruta |
|---|---|
| Mapa principal y sus zonas | `scenes/maps/mapa_completo.tscn` y escenas de esa carpeta |
| Mapa alternativo de selva y jade | `scenes/maps/selva_jade.tscn` — abrir con F6 |
| Jugador | `scenes/player/player.tscn` y `scripts/player/player.gd` |
| Daga | `scenes/weapons/dagger_projectile.tscn` y `scripts/weapons/dagger_projectile.gd` |
| Enemigos | `scenes/enemies/` y `scripts/enemies/` |
| Menú | `scenes/ui/main_menu.tscn` y `scripts/ui/main_menu.gd` |
| Puntos de control | `scenes/interactables/` y `scripts/interactables/` |
| Música y sonidos | `assets/audio/` |
| Imágenes | `assets/graphics/` |
| Recursos TileSet | `resources/tilesets/` |
| Audio global y estado de la sesión | `scripts/autoload/` |

La introducción original permanece en `scenes/cinematics/intro.tscn`. F5 ahora abre directamente el menú, en lugar de esa escena de introducción sin transición al juego.

`docs/rutas_actualizadas.csv` relaciona las rutas antiguas con las nuevas. Mueve o renombra recursos desde el panel de archivos de Godot para que se actualicen las referencias.

## Controles

| Acción | Control |
|---|---|
| Moverse | WASD |
| Correr | Shift |
| Esquivar | Espacio |
| Espada | Clic izquierdo |
| Escudo | Clic derecho |
| Daga | E |
| Curación | R |

La función de vista completa del mapa con M fue eliminada. El mapa alternativo conserva Esc para volver al menú.

## Cómo funcionan las dagas

- La escena del proyectil ya está asignada por defecto.
- E apunta automáticamente al enemigo vivo más cercano **dentro de 450 píxeles**. El borde exacto está incluido.
- Sin objetivos dentro del alcance, no se crea una daga ni se gasta una carga.
- El alcance se cambia en el Inspector del jugador, propiedad **Dagger Range**. La selección del enemigo y el recorrido máximo usan el mismo valor.
- Se mantienen 3 cargas, 40 puntos de daño inicial, 10 de sangrado durante 3 segundos y una carga recuperada cada 3 segundos.
- El HUD muestra las cargas disponibles. El proyectil comprueba el tramo recorrido entre cuadros para evitar saltarse un enemigo.
- El sonido de lanzamiento utiliza el archivo existente, convertido a WAV PCM compatible con Godot.

Para añadir enemigos nuevos que puedan recibir dagas, usa el grupo `enemies` y un método `take_damage(amount)`. Los enemigos originales que reciben daño ya se registran automáticamente, incluidos los murciélagos invocados.

## Qué se optimizó

- Se excluyeron todas las cachés, complementos (incluido Ziva), ejecutables auxiliares, demostraciones de paquetes y recursos sin referencias desde las escenas y scripts conservados.
- Se mantienen los mapas propios, personajes, interfaz, sonidos y licencias usados por este proyecto. El material descartado sigue disponible en tu ZIP original, que no se modificó.
- Cinco pistas largas pasaron a **Ogg Vorbis**. Conservan duración, canales y frecuencia de muestreo; Ogg usa compresión perceptual con pérdida.
- Veintinueve imágenes pasaron a **WebP sin pérdida**, manteniendo dimensiones y píxeles RGBA idénticos.
- La búsqueda de objetivos usa el grupo de enemigos en lugar de recorrer todos los nodos del mapa.

No se redujeron las dimensiones de las imágenes ni se eliminó ningún mapa propio. El menor tamaño de los archivos no implica la misma reducción de memoria gráfica: las texturas mantienen su resolución.

## Verificación

Las pruebas reproducibles están en `tests/regression.gd`. Cubren la carga e instanciación de todas las escenas, el menú y mapa principal, lanzamiento con la tecla E, alcance, daño, sangrado, recarga, HUD y eliminación de la vista de mapa.

Después de importar el proyecto, pueden ejecutarse desde una terminal con:

```text
godot --headless --path RUTA_DEL_PROYECTO --script res://tests/regression.gd
```

Consulta `docs/VERIFICACION.md` para los resultados. No se realizó una partida completa de balance o victoria contra todos los jefes. El checkpoint conserva su funcionamiento durante la sesión, sin añadir guardado en disco.
