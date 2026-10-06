// Todavía no vimos herencia, así que la común y la fantasma son dos clases independientes.
// El polimorfismo sale de que las dos entienden los mismos mensajes (filaDeAterrizajeEn,
// reemplazaAlAterrizar, bajar, image) y cada una responde a su manera.

// Ficha común: cae por la columna y, cuando llega a su fila de aterrizaje, queda apoyada
// (aterriza en la primera fila libre, arriba de la pila).
class Ficha {
  const property jugador
  var property position = null

  method image() = "comun-" + jugador.color() + ".png"

  method bajar() {
    position = position.down(1)
  }

  method filaDeAterrizajeEn(pila) = pila.size()

  method reemplazaAlAterrizar(pila) = false
}

// Ficha fantasma: atraviesa las primeras `atraviesa` fichas de la columna (contando desde arriba)
// y reemplaza la que encuentra en esa posición. Si la columna no tiene tantas fichas, cae como una común.
class FichaFantasma {
  const property jugador
  var property position = null
  const atraviesa = 2

  method image() = "fantasma-" + jugador.color() + ".png"

  method bajar() {
    position = position.down(1)
  }

  method filaDeAterrizajeEn(pila) =
    if (self.reemplazaAlAterrizar(pila)) pila.size() - 1 - atraviesa else pila.size()

  method reemplazaAlAterrizar(pila) = pila.size() > atraviesa
}
