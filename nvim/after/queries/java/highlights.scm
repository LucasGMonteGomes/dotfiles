; extends

; O parser Java classifica o nome de um construtor tambem como tipo. Esta
; captura, aplicada depois da consulta padrao, permite o azul em italico do
; JetBrains Islands sem alterar as demais classes Java.
(constructor_declaration
  name: (identifier) @constructor)
