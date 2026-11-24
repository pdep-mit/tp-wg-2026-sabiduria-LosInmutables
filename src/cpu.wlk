import wollok.game.*
import partida.*

// La CPU juega con las fichas amarillas cuando el modo es contra CPU.
// Decide dónde tirar según su estado (composición): `estado` es otro objeto al que le
// pregunta la columna, pasándole la ficha que le tocó. Arranca en estadoInicio y después
// de las primeras jugadas pasa a estadoJugando.
object cpu {
  const jugadasDeInicio = 2
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
    partida.soltarEn(estado.columnaElegida(partida.tablero(), partida.fichaEnMano(), partida.jugadorRival()))
    jugadas = jugadas + 1
    if (jugadas == jugadasDeInicio) {
      estado = estadoJugando
    }
  }
}

// Estado inicial: pone su ficha al lado de la que acaba de poner el rival (una columna a la
// izquierda o a la derecha). Así el rival no puede armar tres seguidas abajo desde el principio.
// (Recibe los mismos parámetros que estadoJugando aunque no los use: la CPU les habla igual a los dos.)
object estadoInicio {
  method columnaElegida(tablero, ficha, rival) =
    tablero.columnasLibres().filter({ columna => (columna - partida.columnaActual()).abs() == 1 }).anyOne()
}

// Una jugada pensada: tirar esa ficha en esa columna. Se prueba en un tablero hipotético (ver
// Tablero.despuesDeSoltar), así que la CPU puede ver cómo quedaría todo sin mover nada de verdad.
// `ficha` es la copia que se soltó en `tablero`, y ahí quedó en su lugar final.
class Jugada {
  const property columna
  const ficha
  const tablero

  // Con esta jugada la CPU gana (puede ser con una línea o porque algo cayó y armó un 4).
  method gana() = tablero.ganador() == ficha.jugador()

  // La jugada es segura si no le deja el 4 en línea servido al rival: ni porque la propia
  // jugada lo arma (una bomba puede hacer caer sus fichas), ni porque en el turno que sigue
  // tendría una columna donde ganar con una ficha común.
  method esSegura(rival) = tablero.ganador() != rival && tablero.columnasQueArman(rival, tablero.largoParaGanar()).isEmpty()

  method armaLinea(largo) = tablero.formaLineaDe(ficha, largo)
}

// Estado jugando: prueba tirar la ficha que le tocó en cada columna posible y se queda
// con la mejor jugada:
//  1. si alguna jugada gana, esa;
//  2. si no, la que arma la línea propia más larga o, si no, tapa una línea del rival;
//  3. pero siempre una segura: que no le regale la partida al rival.
// Si ninguna es segura, ya perdió: tira a cualquier columna.
object estadoJugando {
  method columnaElegida(tablero, ficha, rival) {
    const jugadas = tablero.columnasDondePuedeSoltar(ficha).map({ columna => self.pensarJugada(tablero, ficha, columna) })
    const ganadoras = jugadas.filter({ jugada => jugada.gana() })
    if (!ganadoras.isEmpty()) {
      return ganadoras.anyOne().columna()
    } else {
      const mejor = self.mejorJugada(tablero, jugadas, rival, tablero.largoParaGanar() - 1)
      return if (mejor != null) mejor.columna() else jugadas.anyOne().columna()
    }
  }

  method pensarJugada(tablero, ficha, columna) {
    const copia = ficha.copia()
    return new Jugada(columna = columna, ficha = copia, tablero = tablero.despuesDeSoltar(copia, columna))
  }

  // Para un largo de línea: una jugada segura que arme esa línea propia; si no hay, una segura que
  // tape la que armaría el rival. Si tampoco, prueba con un largo menor: 3 y 2 son ir sumando.
  // Con largo 1 cualquier jugada arma "una línea", así que si no hubo nada mejor termina al azar.
  // Devuelve null si no hay ninguna jugada segura.
  method mejorJugada(tablero, jugadas, rival, largo) {
    const propia = self.unaSegura(jugadas.filter({ jugada => jugada.armaLinea(largo) }), rival)
    if (propia != null) {
      return propia
    } else if (largo == 1) {
      return null
    } else {
      const columnasDelRival = tablero.columnasQueArman(rival, largo)
      const tapa = self.unaSegura(jugadas.filter({ jugada => columnasDelRival.contains(jugada.columna()) }), rival)
      return if (tapa != null) tapa else self.mejorJugada(tablero, jugadas, rival, largo - 1)
    }
  }

  // Una jugada segura al azar entre esas, o null si ninguna lo es. Se va probando de a una
  // (y no todas juntas) porque revisar si una jugada es segura es lo que más tarda.
  method unaSegura(jugadas, rival) {
    if (jugadas.isEmpty()) {
      return null
    } else {
      const elegida = jugadas.anyOne()
      return if (elegida.esSegura(rival)) elegida else self.unaSegura(jugadas.filter({ jugada => jugada != elegida }), rival)
    }
  }
}
