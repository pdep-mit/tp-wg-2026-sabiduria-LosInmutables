import wollok.game.*

// Ficha: lo que tienen en común todas las fichas (jugador, posición y la mecánica de caer).
// No se crea directamente: se usan FichaComun o FichaFantasma, que se diferencian en
// `image` y en `filaDeAterrizajeEn`, cada una a su manera (polimorfismo).
//
// La ficha se encarga de su propia caída: le pregunta al tablero cuántas fichas hay en su
// columna, decide hasta qué fila tiene que bajar, baja sola y, al llegar, avisa que se apoyó.
class Ficha {
  const property jugador
  var property position = null
  var cayendo = false
  // El motor de Wollok redondea la posición a celda entera antes de dibujarla, así que
  // la caída no puede deslizarse: como mucho se puede elegir qué tan pausado va, celda
  // a celda. Este es el único número para ajustar esa pausa.
  const milisegundosPorCelda = 200

  method estaCayendo() = cayendo

  method estaApoyada() = !cayendo

  method estaEnColumna(columna) = position.x() == columna

  method estaEn(otraPosicion) = position.x() == otraPosicion.x() && position.y() == otraPosicion.y()

  // Cantidad de fichas apoyadas en la columna sobre la que está la ficha.
  method alturaDeSuColumnaEn(tablero) = tablero.alturaDe(position.x())

  method imagenDe(tipo) = tipo + "-" + jugador.color() + ".png"

  method bajar() {
    position = position.down(1)
  }

  // Empieza a caer hasta la fila indicada.
  method caerHasta(fila, tablero) {
    cayendo = true
    self.avanzarHasta(fila, tablero)
  }

  // Baja una celda y programa el siguiente paso; al llegar a su fila, se apoya.
  method avanzarHasta(fila, tablero) {
    if (position.y() > fila) {
      self.bajar()
      game.schedule(milisegundosPorCelda, { self.avanzarHasta(fila, tablero) })
    } else {
      self.aterrizar(tablero)
    }
  }

  method aterrizar(tablero) {
    cayendo = false
    tablero.apoyar(self)
  }
}

// Ficha común: queda apoyada arriba de las fichas que ya hay en la columna.
class FichaComun inherits Ficha {
  method image() = self.imagenDe("comun")

  method filaDeAterrizajeEn(tablero) = self.alturaDeSuColumnaEn(tablero)
}

// Ficha fantasma: atraviesa las primeras `atraviesa` fichas de la columna (contando desde arriba)
// y reemplaza la que encuentra. Si la columna no tiene más de `atraviesa` fichas, cae como una común.
class FichaFantasma inherits Ficha {
  const atraviesa = 2

  method image() = self.imagenDe("fantasma")

  method filaDeAterrizajeEn(tablero) {
    const altura = self.alturaDeSuColumnaEn(tablero)
    return if (altura > atraviesa) altura - 1 - atraviesa else altura
  }
}
