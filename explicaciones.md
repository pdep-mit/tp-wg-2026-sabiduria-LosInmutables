# Explicaciones teóricas

En este proyecto se aplicaron varios conceptos de programación orientada a objetos de manera directa y consistente con la lógica del juego. La estructura principal se basa en la separación entre las fichas, el tablero y la partida.

## Herencia

La herencia se usa en la jerarquía de fichas. La clase `Ficha` representa el comportamiento común a todas las piezas del juego: tienen un jugador, una posición, pueden estar cayendo o apoyadas, y comparten la lógica de movimiento vertical y de aterrizaje.

A partir de esa clase base, se crean dos especializaciones:

- `FichaComun`: representa la ficha normal. Su comportamiento es simple: cae hasta la primera fila libre de la columna.
- `FichaFantasma`: extiende a `Ficha` y redefine el cálculo de la fila de aterrizaje para que atraviese algunas fichas previas y reemplaze la última.

Esto permite reutilizar la lógica general (`caerHasta`, `avanzarHasta`, `aterrizar`, etc.) sin duplicar el código, y a la vez darle un comportamiento específico a cada tipo de ficha. La clase base es la abstracción común; las subclases agregan la diferencia.

## Polimorfismo

El polimorfismo aparece cuando distintas subclases de `Ficha` responden al mismo mensaje de distintas maneras. Por ejemplo, ambos tipos de ficha entienden el mensaje `filaDeAterrizajeEn(tablero)`, pero cada uno lo implementa con una lógica distinta:

- `FichaComun#filaDeAterrizajeEn` calcula la altura de la columna y la usa como fila final.
- `FichaFantasma#filaDeAterrizajeEn` calcula una fila más baja si la columna tiene piezas acumuladas y el efecto fantasma puede atravesarlas.

Además, el tablero usa mensajes genéricos como `soltar(ficha, columna)` y `apoyar(ficha)`, sin depender de qué tipo concreto de ficha es. La misma operación es ejecutada sobre distintos objetos que comparten la interfaz de `Ficha`. Eso es polimorfismo en acción: el código cliente depende de la abstracción, no del tipo particular.

Otro caso claro es el uso de `image()`: cada subclase redefine la representación visual de la ficha, pero el resto de la lógica no necesita saber si la pieza es común o fantasma. Esto hace que el código sea más extensible y menos acoplado.

## Colecciones

Las colecciones son fundamentales para modelar el estado del tablero y la lógica del juego. En `Tablero`, la lista `fichas` guarda todas las piezas que ya fueron soltadas, tanto las apoyadas como la que está cayendo.

Con esta colección se resuelven varias tareas:

- `fichas.filter(...)` para obtener solo las fichas apoyadas de una columna concreta.
- `fichas.any(...)` para saber si hay una ficha en movimiento.
- `fichas.removeAll(...)` para sacar fichas reemplazadas por otra fantasma.
- `fichas.forEach(...)` para limpiar el tablero al reiniciar la partida.

También se usa para detectar el ganador: `fichaApoyadaEn(x, y)` busca en la colección la pieza apoyada que está en una determinada posición. Esto permite recorrer el tablero como un conjunto de objetos y consultar condiciones con un estilo declarativo.

La colección no sólo almacena datos, sino que aporta la semántica de la partida: la cantidad de fichas por columna, el reemplazo de piezas fantasma y la verificación de línea completa.

## Relación con el juego

La partida encapsula la regla del turno y el estado del juego: jugador actual, ficha en mano y columna elegida. Por su parte, el tablero conoce cómo se comporta la estructura física del juego, y cada ficha sabe cómo cae y dónde aterriza. La separación de responsabilidades hace que la solución sea clara y mantenible.

# Diagramas

A continuación se incluye un diagrama de clases en sintaxis YUML. Sirve para resumir la estructura del sistema y las relaciones entre objetos del juego.

![Diagrama de clases del juego](https://yuml.me/0160c093.jpg)