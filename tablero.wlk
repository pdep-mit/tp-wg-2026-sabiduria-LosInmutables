import wollok.game.*

// Tablero de Cuatro en línea (7 columnas x 6 filas).
// Cada columna es una lista de fichas ordenada de abajo hacia arriba: la posición de una ficha
// dentro de esa lista (0 = la de abajo) es su fila, por lo que las fichas siempre quedan apoyadas.
// Las fichas que todavía están cayendo no están en las columnas: entran cuando se apoyan.
class Tablero {
  const property columnas = 7
  const property filas = 6
  const pilas = []
  const cayendo = []

  method initialize() {
    columnas.times({ n => pilas.add([]) })
  }

  method fichasEn(columna) = pilas.get(columna)

  method columnaLlena(columna) = pilas.get(columna).size() == filas

  method hayFichaCayendo() = !cayendo.isEmpty()

  // La ficha ya estaba flotando en la fila extra sobre el tablero (ya es un visual):
  // alcanza con confirmar su columna y empezar a hacerla caer.
  method soltar(ficha, columna) {
    ficha.position(game.at(columna, filas))
    cayendo.add(ficha)
  }

  // Se ejecuta en cada tick: las fichas que llegaron a su fila de aterrizaje se apoyan
  // (cada tipo de ficha decide esa fila) y las demás bajan una celda.
  method avanzarCaida() {
    const apoyadas = cayendo.filter({ ficha => !self.hayLugarDebajoDe(ficha) })
    cayendo.removeAll(apoyadas)
    apoyadas.forEach({ ficha => self.apoyar(ficha) })
    cayendo.forEach({ ficha => ficha.bajar() })
  }

  method hayLugarDebajoDe(ficha) = ficha.position().y() > ficha.filaDeAterrizajeEn(self.pilaDe(ficha))

  method pilaDe(ficha) = pilas.get(ficha.position().x())

  // Común: se agrega arriba de la pila. Fantasma: si hay suficientes fichas para atravesar,
  // reemplaza la que encuentra en su fila (las demás quedan en su lugar); si no, cae como una común.
  method apoyar(ficha) {
    const pila = self.pilaDe(ficha)
    const fila = ficha.filaDeAterrizajeEn(pila)
    if (ficha.reemplazaAlAterrizar(pila)) {
      self.reemplazarEnFila(pila, fila, ficha)
    } else {
      pila.add(ficha)
    }
  }

  // Saca la ficha que estaba en esa fila de la columna y pone la nueva en su lugar, sin mover a las demás.
  method reemplazarEnFila(pila, fila, ficha) {
    game.removeVisual(pila.get(fila))
    const conReemplazo = []
    pila.size().times({ n =>
      const indice = n - 1
      if (indice == fila) {
        conReemplazo.add(ficha)
      } else {
        conReemplazo.add(pila.get(indice))
      }
    })
    pila.clear()
    conReemplazo.forEach({ f => pila.add(f) })
  }
}
