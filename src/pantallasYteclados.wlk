
//------------------[Pantalla]------------------------
//La idea de esta clase es que controle las imagenes  
//y elementos que aparecen en las distintas pantallas
class Pantalla{

}

object menuInicial inherits Pantalla {
    //Aparezca logo, "jugar", "como jugar" uno al lado del otro
    //Si selecciona jugar va a pantalla seleccion modo
    //Si selecciona como jugar va a pantalla como jugar
}

object pantallaComoJugar inherits Pantalla {
    //explicacion teclas, fichas y tableros
}

object pantallaSeleccionModo inherits Pantalla {
    //Pantalla dividida con una linea vertical del lado izquierdo aparece
    //jugador 1 y por defecto CPU del lado derecho pero abajo un texto que diga apretar
    //Espacio para jugador 2 y aparece la imagen de jugador 2 con sus teclas
    //si jugador 1 apreta enter antes que jugador 2 aprete espacio va contra el bot 
    
}

object pantallaSeleccionTablero inherits Pantalla {
    //pequeña imagen de cada tablero con su nombre cada jugador navega entre ellos y elije uno
}

object pantallaJuego inherits Pantalla {
    //Pasamos al tablero como lo conocemos
}

//------------------[Teclado]------------------------
//Cada teclado va a saber que hace cada tecla en cada pantalla,asi es mas intuitivo y no tenemos que poner una tecla distitna para cada accion
//ademas suma herencia y polimorfismo ;)
class Teclado{

    method a(pantalla){}
    method d(pantalla){}
    method espacio(pantalla){}
    method izquierda(pantalla){}
    method derecha(pantalla){}
    method enter(pantalla){}
    method backspace(pantalla){}
    


}

object tecladoMenuInicial inherits Teclado {
    //con las flechas cambias entre juegar y como jugar con enter elejis
    override method a(pantalla){
        pantalla.toggle(); 
        //Esto creo que es lo contrario a polimorfismo pq la idea es que lo entienda solo la de menuInicial y que no se llame si no se esta en esta pantalla
    }
    //Ambas pueden hacer toggle porque solo va a haber 2 opciones Jugar o Como Jugar, si hay mas podriamos hacer una lista y que te mueva por la lista o poner 1 letra por opcion
    override method d(pantalla){
        pantalla.toggle(); 
        //Esto creo que es lo contrario a polimorfismo pq la idea es que lo entienda solo la de menuInicial y que no se llame si no se esta en esta pantalla
    }
    override method enter(pantalla){
        pantalla.confirmar()
    }
}

object tecladoComoJugar inherits Teclado {
    //solo va a haber texto no se interactua con flechas, con escape volves a menu inicial
    override method backspace(pantalla){
        pantalla.volver()
    }
}

object tecladoSeleccionModo inherits Teclado {
    //si se apreta enter de una pasas a jugar, sino con espacio se agrega el otro jugador
    //con escape volves a menu inicial
    override method espacio(pantalla){
        pantalla.confirmarJugador1()
    }
    override method enter(pantalla){
        pantalla.confirmarJugador2()
    }
    override method backspace(pantalla){
        pantalla.volver()
    }
}

object tecladoSeleccionTablero inherits Teclado {
    //cada jugador con sus respectivas teclas de movimiento (AD o flechas) navega entre los tableros
    //con la respectiva tecla de confirmacion (espacio o enter) elige un tablero
    //con escape volves a seleccionmodo
    override method a(pantalla){
        pantalla.desplazarIzquierdaJugador1()
    }
    override method d(pantalla){
        pantalla.desplazarDerechaJugador1()
    }
    override method izquierda(pantalla){
        pantalla.desplazarIzquierdaJugador2()
    }
    override method derecha(pantalla){
        pantalla.desplazarDerechaJugador2()
    }
    override method espacio(pantalla){
        pantalla.confirmarJugador1()
    }
    override method enter(pantalla){
        pantalla.confirmarJugador2()
    }
    override method backspace(pantalla){
        pantalla.volver()
    }
    
}

object tecladoJuego inherits Teclado {
    //cada jugador controla su ficha con ad o las flechas y la tira con espacio o enter
    //si tiene la ficha disponible con f cambia a la fantasma,b a la bomba, t a la tetris
    //con escape volves a menu inicial
    override method a(pantalla){
        pantalla.desplazarIzquierdaJugador1()
    }
    override method d(pantalla){
        pantalla.desplazarDerechaJugador1()
    }
    override method izquierda(pantalla){
        pantalla.desplazarIzquierdaJugador2()
    }
    override method derecha(pantalla){
        pantalla.desplazarDerechaJugador2()
    }
    override method espacio(pantalla){
        pantalla.confirmarJugador1()
    }
    override method enter(pantalla){
        pantalla.confirmarJugador2()
    }
    override method backspace(pantalla){
        pantalla.volver()
    }
    //Implementar las letras para las fichas especiales, pero se me ocurria que en la barra
    //de fichas disponible vayas cambiando con shift por ejemplo o puede ser con la W y la flecha para arriba
    //seria otra opcion donde usar una lista ;)
}