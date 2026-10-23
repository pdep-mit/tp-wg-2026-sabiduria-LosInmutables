import tablero.*
import fichas.*

class Jugador {
  const property color
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

  method jugadorActual() = jugadorActual

  // Mientras nadie ganó se puede seguir jugando. Una vez que hay ganador, el tablero
  // queda congelado: ni se mueve la ficha en mano, ni se elige otro tipo, ni se suelta.
  method jugando() = !tablero.hayGanador()

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
  method ponerEnMano(ficha) {
    fichaEnMano = ficha
    self.actualizarPosicionDeFichaEnMano()
    game.addVisual(fichaEnMano)
  }

  method actualizarPosicionDeFichaEnMano() {
    fichaEnMano.position(game.at(columnaActual, tablero.filas()))
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
  // Si ya hay ganador, jugando() corta todo antes de llegar a mirar esto.
  method soltar() {
    if (self.jugando() && !tablero.hayFichaCayendo() && !tablero.columnaLlena(columnaActual)) {
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
