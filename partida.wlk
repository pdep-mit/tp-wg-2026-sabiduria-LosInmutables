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
  var property fichaEnMano = new Ficha(jugador = jugadorRojo)

  method jugadorActual() = jugadorActual

  method elegirComun() {
    fichaEnMano = new Ficha(jugador = jugadorActual)
  }

  method elegirFantasma() {
    fichaEnMano = new FichaFantasma(jugador = jugadorActual)
  }

  // Si hay una ficha cayendo o la columna está llena no se puede soltar y el turno no pasa.
  method soltarEn(columna) {
    if (!tablero.hayFichaCayendo() && !tablero.columnaLlena(columna)) {
      tablero.soltar(fichaEnMano, columna)
      self.pasarTurno()
    }
  }

  method pasarTurno() {
    if (jugadorActual == jugadorRojo) {
      jugadorActual = jugadorAmarillo
    } else {
      jugadorActual = jugadorRojo
    }
    self.elegirComun()
  }
}
