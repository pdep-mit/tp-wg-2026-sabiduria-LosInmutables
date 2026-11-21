import wollok.game.*
import partida.*

// La CPU juega con las fichas amarillas cuando el modo es contra CPU.
// Decide dónde tirar según su estado (composición): `estado` es otro objeto al que le
// pregunta la columna. Arranca en estadoInicio (al azar) y después de unas pocas jugadas
// pasa a estadoJugando, que ya sigue una regla.
object cpu {
  const jugadasAlAzar = 3
  var estado = estadoInicio
  var jugadas = 0

  // Nueva partida: vuelve a empezar desde el estado inicial.
  method reiniciar() {
    estado = estadoInicio
    jugadas = 0
  }

  // Juega su turno en cuanto no haya ninguna ficha cayendo; si todavía cae alguna,
  // vuelve a mirar en un rato (igual que Ficha.avanzarHasta con game.schedule).
  // Si mientras esperaba se reinició la partida o se salió de la pantalla, no hace nada.
  method jugar() {
    if (partida.turnoDeLaCPU() && partida.jugando()) {
      if (partida.tablero().hayFichaCayendo()) {
        game.schedule(300, { self.jugar() })
      } else {
        self.tirar()
      }
    }
  }

  method tirar() {
    partida.soltarEn(estado.columnaElegida(partida.tablero(), partida.jugadorActual()))
    jugadas = jugadas + 1
    if (jugadas == jugadasAlAzar) {
      estado = estadoJugando
    }
  }
}

// Estado inicial: tira en cualquier columna que no esté llena.
object estadoInicio {
  method columnaElegida(tablero, jugador) = tablero.columnasLibres().anyOne()
}

// Estado jugando. Regla por ahora: si en alguna columna gana, tira ahí; si no, al azar.
object estadoJugando {
  method columnaElegida(tablero, jugador) {
    const ganadoras = tablero.columnasLibres().filter({ columna => tablero.ganaSiSueltaEn(jugador, columna) })
    return if (ganadoras.isEmpty()) tablero.columnasLibres().anyOne() else ganadoras.first()
  }
}
