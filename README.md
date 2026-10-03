# CH'ATOJ

Prototipo de acción y exploración en 2D inspirado en la selva, el jade y la
fantasía mesoamericana. El jugador recorre zonas, combate enemigos y jefes, y
puede usar espada, escudo, esquiva, dagas y consumibles de curación.

## Narrativa y enfoque cultural

CH'ATOJ propone una aventura fantástica en un mundo de selva y ruinas inspirado
en motivos mayas. Sus escenarios, criaturas, objetos de jade, música y diseño
visual construyen la ambientación. El prototipo todavía no presenta una
narrativa lineal completa: la introducción cinemática está conservada como
escena independiente y no forma parte del flujo principal de inicio.

La música y el arte son recursos de ambientación; no se presentan como
reconstrucciones históricas de instrumentos, prácticas o símbolos mayas. Para
la entrega del concurso, el equipo debe complementar este enfoque con sus
fuentes de investigación y explicar las decisiones culturales en el video.

## Requisitos

- Godot **4.7.2 Standard** o una versión compatible con el proyecto (Godot 4.7).
- Windows, macOS o Linux de 64 bits.
- Pantalla recomendada: 1280 × 720.
- Renderer GL Compatibility; no requiere complementos externos.
- El motor no está incluido en el repositorio.

## Instalación y ejecución

1. Instala Godot 4.7.2 Standard.
2. Abre el gestor de proyectos de Godot y selecciona **Importar**.
3. Selecciona `Project/CHATOJ/CHATOJ/project.godot` dentro de este repositorio.
4. Espera a que finalice la importación de recursos y pulsa **F5** para ejecutar
   el proyecto y abrir el menú principal.
5. Elige **Jugar**.

También se puede ejecutar desde una terminal situada en la raíz del repositorio:

```sh
godot --path Project/CHATOJ/CHATOJ
```

En Windows, sustituye `godot` por la ruta o el nombre del ejecutable de Godot
instalado. Para pasos detallados, controles, resolución de problemas y pruebas,
consulta el [manual de instalación y ejecución](docs/manual-instalacion.pdf).

## Controles

| Acción | Control |
| --- | --- |
| Moverse | W, A, S, D |
| Correr | Shift |
| Esquivar | Espacio |
| Atacar con espada | Clic izquierdo |
| Levantar el escudo | Mantener clic derecho |
| Lanzar una daga al enemigo cercano | E |
| Usar curación | R |

El menú principal permite iniciar o cerrar el juego. Durante la partida,
Escape o el botón de menú regresan al menú principal.

## Estructura del proyecto

El proyecto Godot está en `Project/CHATOJ/CHATOJ/`.

| Ruta | Contenido |
| --- | --- |
| `scenes/maps/` | Mapas y zonas jugables |
| `scenes/player/` | Escena del personaje |
| `scenes/enemies/` | Escenas de enemigos y jefes |
| `scenes/ui/` | Menú principal e interfaz |
| `scripts/` | Lógica del jugador, enemigos, audio, estado e interacciones |
| `assets/graphics/` | Arte y recursos visuales |
| `assets/audio/` | Música, ambiente y efectos de sonido |
| `tests/regression.gd` | Pruebas automatizadas de regresión |
| `docs/VERIFICACION.md` | Alcance y resultados de verificación registrados |

La escena principal es `scenes/ui/main_menu.tscn`; el botón **Jugar** abre
`scenes/maps/mapa_completo.tscn`. El mapa `selva_jade.tscn` se puede abrir
directamente desde el editor con F6.

## Pruebas

Con Godot instalado y el proyecto importado, desde la raíz del repositorio:

```sh
godot --headless --path Project/CHATOJ/CHATOJ \
  --script res://tests/regression.gd
```

El informe del repositorio registra 75 comprobaciones aprobadas y 0 fallos en
la última ejecución documentada. No equivale a una prueba completa de balance
ni a una partida de principio a fin.

## Entrega del concurso

- [Manual de instalación y ejecución (PDF)](docs/manual-instalacion.pdf)
- [Documento oficial de entrega (PDF)](docs/entrega-oficial.pdf)
- [Guion para el video de presentación](docs/guion-video.md)
- Enlaces de repositorio, ejecutable y video incluidos en el documento oficial.

Los datos personales del equipo y los enlaces al ejecutable y al video deben
completarse antes de enviar la entrega.
