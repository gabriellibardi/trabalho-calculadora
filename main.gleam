// Trabalho 03 - Calculadora
// Alunos: Gabriel Libardi Lulu (134728) e Vitor da Rocha Machado (132769)

// Análise
//
// Implementar um programa que calcula o valor de uma expressão de entrada, representada por uma string
// na notação infixa, isto é, com os operadores entre os operandos.
// A expressão de entrada é composta por uma string que pode conter números de 0 à 9, '(', ')' e os qua-
// tro operadores primários: '+', '-', '*', '/'. A expressão pode conter espaços em branco.

// Passo a passo
//
// 1 - Converter a entrada para uma lista de um tipo de dado que representa um símbolo de uma expressão.

// 2 - Converter a expressão na notação pré-fixa para a notação pós-fixa.
//      a. Analisar a expressão da esquerda para a direita, um símbolo por vez.
//          -> Se o símbolo for um operando, adicionar à saída.
//          -> Se o símbolo for um operador:
//               - Enquanto o topo da pilha tiver um operador de maior precedência ou de igual precedên-
//                 cia, desempilhar o operador e adicionar à saída.
//               - Empilhar o operador.
//          -> Se o símbolo for um parêntese de abertura, empilhar.
//          -> Se o símbolo for um parêntese de fechamento, desempilhar os operadores até encontrar o
//             parêntese de abertura.
//      b. Desempilhar os operadores restantes e adicionar à saída.

// 3 - Avaliar a expressão na notação pós-fixa.
//      a. Analisar a expressão da esquerda para a direita, um símbolo por vez.
//          -> Se o símbolo for um operando, empilhar o valor.
//          -> Se o símbolo for um operador, desempilhar dois valores, aplicar o operador e empilhar o
//             resultado.
//      b. O valor final é o único valor restante na pilha.

import sgleam/check

/// Conjunto de possíveis erros que podem ocorrer durante a execução do programa.
pub type Erro {
  CaractereInvalido
  ExpressaoInvalida
  DivisaoPorZero
}

pub type Operador {
  Soma
  Subtracao
  Multiplicacao
  Divisao
}

/// Simbolo de uma expressão.
pub type Simbolo {
  Operando(Int)
  Operador(Operador)
  ParenteseAbertura
  ParenteseFechamento
}

/// Avalia uma expressão na notação pós-fixa.
pub fn avaliar_posfixa(
  expressao: List(Simbolo),
  pilha: List(Simbolo),
) -> Result(Simbolo, Erro) {
  case expressao {
    [] ->
      case pilha {
        [valor] -> Ok(valor)
        _ -> Error(ExpressaoInvalida)
      }
    [primeiro, ..resto] -> {
      case primeiro {
        Operando(valor) -> avaliar_posfixa(resto, [Operando(valor), ..pilha])
        Operador(operador) -> {
          case pilha {
            [Operando(valor2), Operando(valor1), ..resto_pilha] -> {
              let resultado = case operador {
                Soma -> valor1 + valor2
                Subtracao -> valor1 - valor2
                Multiplicacao -> valor1 * valor2
                Divisao -> valor1 / valor2
              }
              avaliar_posfixa(resto, [Operando(resultado), ..resto_pilha])
            }
            _ -> Error(ExpressaoInvalida)
          }
        }
        _ -> Error(ExpressaoInvalida)
      }
    }
  }
}

pub fn avaliar_posfixa_examples() {
  check.eq(avaliar_posfixa([], []), Error(ExpressaoInvalida))
  check.eq(avaliar_posfixa([Operando(10)], []), Ok(Operando(10)))
  // 2 3 + ou 2 + 3
  check.eq(
    avaliar_posfixa([Operando(2), Operando(3), Operador(Soma)], []),
    Ok(Operando(5)),
  )
  // 832*- ou 8 - 3 * 2
  check.eq(
    avaliar_posfixa(
      [
        Operando(8),
        Operando(3),
        Operando(2),
        Operador(Multiplicacao),
        Operador(Subtracao),
      ],
      [],
    ),
    Ok(Operando(2)),
  )
  // 83-2* ou (8 - 3) * 2
  check.eq(
    avaliar_posfixa(
      [
        Operando(8),
        Operando(3),
        Operador(Subtracao),
        Operando(2),
        Operador(Multiplicacao),
      ],
      [],
    ),
    Ok(Operando(10)),
  )
  // 37*41-/2+ ou 3 * 7 / (4 - 1) + 2
  check.eq(
    avaliar_posfixa(
      [
        Operando(3),
        Operando(7),
        Operador(Multiplicacao),
        Operando(4),
        Operando(1),
        Operador(Subtracao),
        Operador(Divisao),
        Operando(2),
        Operador(Soma),
      ],
      [],
    ),
    Ok(Operando(9)),
  )
  // 82+0/ ou (8 + 2) / 0
  check.eq(
    avaliar_posfixa(
      [Operando(8), Operando(2), Operador(Soma), Operando(0), Operador(Divisao)],
      [],
    ),
    Ok(Operando(0)),
  )
  check.eq(
    avaliar_posfixa([Operador(Multiplicacao)], []),
    Error(ExpressaoInvalida),
  )
}
