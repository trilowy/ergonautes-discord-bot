# Disposition clavier vs configuration clavier

Disposition clavier (Ergo‑L, QWERTY, etc) : emplacement des lettres, chiffres, symboles sur les touches

Configuration clavier programmable ([Selenium](https://onedeadkey.github.io/selenium/), Miryoku, …) : configuration du logiciel du clavier (appelée *firmware*) installé dans les claviers programmables qui modifie l’emplacement des touches elle-mêmes.

On va préférer installer une disposition clavier sur l’ordinateur pour qu’elle gère ce que produisent les touches (par exemple [Ergo‑L](https://ergol.org/installation/) qui configure les caractères spéciaux, majuscules accentuées, etc), et, accessoirement, programmer le clavier pour déplacer les modificateurs (comme `Shift`, `Ctrl`, `Alt`) mais aussi `Échap`, flèches de navigation, `Backspace`, etc, sur des endroits plus confortables comme les touches de pouces ou sur des *layers* par exemple.

S’il n’y a pas le choix (blocage de l’ordinateur, même pour les pilotes nomades), on peut émuler la disposition Ergo‑L via une programmation du clavier, mais ça sera toujours moins complet que le pilote installé directement sur l’ordinateur, c’est pourquoi on ne le recommande qu’en solution de secours. Pour une émulation toute faite activable par option, se référer à l’implémentation [ZMK de Selenium](https://github.com/OneDeadKey/zmk-config-aekeynox).
