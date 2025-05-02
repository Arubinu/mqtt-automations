import ..classes.ikea-styrbar as switch

import .debug as debug
//import .alvin as alvin


init:
  Color ::= switch.Color
  Brightness ::= switch.Brightness
  Temperature ::= switch.Temperature

  debug.init --default-color=Color --default-brightness=Brightness --default-temperature=Temperature
  debug.add
  debug.lock-subscribe

  //alvin.init --default-color=Color --default-brightness=Brightness --default-temperature=Temperature
  //alvin.add
  //alvin.lock-subscribe