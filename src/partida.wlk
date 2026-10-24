import tablero.*
import fichas.*

class Jugador {
  const property color
}

// Vista previa de la ficha fantasma: una copia que parpadea en la celda donde va a terminar
// cayendo la ficha en mano. No guarda nada propio: su posición y su imagen las calcula
// la partida cada vez que se dibuja, así que siempre acompaña a la ficha en mano.
object sombraDelFantasma {
  method position() = partida.posicionDeAterrizaje()

  method image() = partida.fichaEnMano().image()
}

// Partida 1 vs 1 local: siempre son los mismos dos jugadores, que se turnan.
object partida {
  const property tablero = new Tablero()
  const jugadorRojo = new Jugador(color = "rojo")
  const jugadorAmarillo = new Jugador(color = "amarillo")
  var jugadorActual = jugadorRojo
  var property fichaEnMano = new FichaComun(jugador = jugadorRojo)
  // Columna sobre la que "flota" la ficha en mano (fila extra, arriba del tablero).
  var columnaActual = 3

  // Mientras nadie ganó ni empataron se puede seguir jugando. Una vez que termina la partida,
  // el tablero queda congelado: ni se mueve la ficha en mano, ni se elige otro tipo, ni se suelta.
  method jugando() = !tablero.hayGanador() && !tablero.hayEmpate()

  // Se llama desde el program, antes de game.start(): muestra la primera ficha flotando.
  method iniciar() {
    self.ponerEnMano(fichaEnMano)
  }

  // Vuelve a dejar la partida como al principio: tablero vacío, sin ganador,
  // el turno para el rojo y una ficha común nueva en mano.
  method reiniciar() {
    game.removeVisual(fichaEnMano)
    tablero.reiniciar()
    jugadorActual = jugadorRojo
    columnaActual = 3
    self.ponerEnMano(new FichaComun(jugador = jugadorRojo))
  }

  // Deja la ficha como la que está en mano y la muestra flotando en la columna actual.
  // Cualquier sombra que hubiera era de la ficha anterior: se saca (el parpadeo la vuelve
  // a mostrar si la nueva es fantasma).
  method ponerEnMano(ficha) {
    fichaEnMano = ficha
    self.actualizarPosicionDeFichaEnMano()
    game.addVisual(fichaEnMano)
    game.removeVisual(sombraDelFantasma)
  }

  method actualizarPosicionDeFichaEnMano() {
    fichaEnMano.position(game.at(columnaActual, tablero.filas()))
  }

  // Celda donde terminaría la ficha en mano si se soltara ahora en la columna actual.
  method posicionDeAterrizaje() = game.at(columnaActual, fichaEnMano.filaDeAterrizajeEn(tablero))

  // Se llama a intervalos regulares desde el program: si la sombra se ve la saca y si no se
  // ve la pone, lo que da el parpadeo. Solo aparece si la ficha en mano reemplaza otra.
  method parpadearSombra() {
    if (game.hasVisual(sombraDelFantasma)) {
      game.removeVisual(sombraDelFantasma)
    } else if (fichaEnMano.reemplaza() && self.jugando()) {
      game.addVisual(sombraDelFantasma)
    }
  }

  // Cambiar de tipo de ficha: se saca la que flotaba y se pone la nueva en el mismo lugar.
  method elegirComun() {
    if (self.jugando()) {
      game.removeVisual(fichaEnMano)
      self.ponerEnMano(new FichaComun(jugador = jugadorActual))
    }
  }

  method elegirFantasma() {
    if (self.jugando()) {
      game.removeVisual(fichaEnMano)
      self.ponerEnMano(new FichaFantasma(jugador = jugadorActual))
    }
  }

  method elegirBomba() {
    if (self.jugando()) {
      game.removeVisual(fichaEnMano)
      self.ponerEnMano(new FichaBomba(jugador = jugadorActual))
    }
  }

  // Mover la ficha flotante sin salirse del tablero.
  method desplazarIzquierda() {
    if (self.jugando() && columnaActual > 0) {
      columnaActual = columnaActual - 1
      self.actualizarPosicionDeFichaEnMano()
    }
  }

  method desplazarDerecha() {
    if (self.jugando() && columnaActual < tablero.columnas() - 1) {
      columnaActual = columnaActual + 1
      self.actualizarPosicionDeFichaEnMano()
    }
  }

  // Si hay una ficha cayendo o la columna está llena no se puede soltar y el turno no pasa.
  // Si la partida ya terminó, jugando() corta todo antes de llegar a mirar esto.
  method soltar() {
    if (self.jugando() && !tablero.hayFichaCayendo() && (!tablero.columnaLlena(columnaActual) || fichaEnMano.reemplaza())) {
      tablero.soltar(fichaEnMano, columnaActual)
      self.pasarTurno()
    }
  }

  method pasarTurno() {
    if (jugadorActual == jugadorRojo) {
      jugadorActual = jugadorAmarillo
    } else {
      jugadorActual = jugadorRojo
    }
    self.ponerEnMano(new FichaComun(jugador = jugadorActual))
  }
}
