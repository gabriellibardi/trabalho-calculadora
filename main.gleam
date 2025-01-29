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

import gleam/list
import gleam/result
import sgleam/check

/// Conjunto de possíveis erros que podem ocorrer durante a execução do programa.
pub type Erro {
  CaractereInvalido
  ExpressaoInvalida
}

pub type Operacao {
  Soma
  Subtracao
  Multiplicacao
  Divisao
}

pub type Agrupador {
  ParenteseAbertura
  ParenteseFechamento
}

/// Simbolo de uma expressão.
pub type Simbolo {
  Operando(Int)
  Operador(Operacao)
  Agrupador(Agrupador)
}

pub fn main(expressao: String) -> Result(Int, Erro) {
  todo
}

pub fn main_examples() {
  check.eq("2 + 2", Ok(4))
  check.eq("10 - 3", Ok(7))
  check.eq("4 * 5", Ok(20))
  check.eq("20 / 4", Ok(5))
  check.eq("1 + 2 * 3", Ok(7))
  check.eq("(1 + 2) * 3", Ok(9))
  check.eq("10 / 2 + 3", Ok(8))
  check.eq("10 / (2 + 3)", Ok(2))
  check.eq("   5 +  3   ", Ok(8))
  check.eq("7 * (2 + 3) ", Ok(35))
  check.eq("1 + 2 * (3 + 4) - 5 / (2 + 3)", Ok(13))
  check.eq("(10 - 5) * ((3 + 2) / 5)", Ok(5))
  check.eq("((1 + 1) * (2 + 2)) / 2", Ok(4))
  check.eq("1000000 + 2000000", Ok(3_000_000))
  check.eq("123456 * 654321", Ok(80_779_853_376))
  check.eq("2 + ", Error(ExpressaoInvalida))
  check.eq("4 * (3 - )", Error(ExpressaoInvalida))
  check.eq("(2 + 3", Error(ExpressaoInvalida))
  check.eq("hello + world", Error(CaractereInvalido))
  check.eq("", Error(ExpressaoInvalida))
}

pub fn avaliar_posfixa(expressao: List(Simbolo)) -> Result(Int, Erro) {
  avaliar_posfixa_loop(expressao, [])
}

pub fn avaliar_posfixa_loop(
  expressao: List(Simbolo),
  pilha: List(Int),
) -> Result(Int, Erro) {
  let resultado_final =
    list.try_fold(expressao, pilha, fn(pilha, elem) {
      case elem {
        Operando(valor) -> Ok([valor, ..pilha])
        Operador(operador) -> {
          use #(valor1, valor2, resto_pilha) <- result.try(desempilha_dois(
            pilha,
          ))
          Ok([realiza_operacao(valor2, valor1, operador), ..resto_pilha])
        }
        _ -> Error(ExpressaoInvalida)
      }
    })
  case resultado_final {
    Ok([valor]) -> Ok(valor)
    _ -> Error(ExpressaoInvalida)
  }
}

pub fn avaliar_posfixa_examples() {
  check.eq(avaliar_posfixa([]), Error(ExpressaoInvalida))
  check.eq(avaliar_posfixa([Operando(10)]), Ok(10))
  // 2 3 + ou 2 + 3
  check.eq(avaliar_posfixa([Operando(2), Operando(3), Operador(Soma)]), Ok(5))
  // 832*- ou 8 - 3 * 2
  check.eq(
    avaliar_posfixa([
      Operando(8),
      Operando(3),
      Operando(2),
      Operador(Multiplicacao),
      Operador(Subtracao),
    ]),
    Ok(2),
  )
  // 83-2* ou (8 - 3) * 2
  check.eq(
    avaliar_posfixa([
      Operando(8),
      Operando(3),
      Operador(Subtracao),
      Operando(2),
      Operador(Multiplicacao),
    ]),
    Ok(10),
  )
  // 37*41-/2+ ou 3 * 7 / (4 - 1) + 2
  check.eq(
    avaliar_posfixa([
      Operando(3),
      Operando(7),
      Operador(Multiplicacao),
      Operando(4),
      Operando(1),
      Operador(Subtracao),
      Operador(Divisao),
      Operando(2),
      Operador(Soma),
    ]),
    Ok(9),
  )
  // 82+0/ ou (8 + 2) / 0
  // Divisão por 0 em gleam resulta em 0
  check.eq(
    avaliar_posfixa([
      Operando(8),
      Operando(2),
      Operador(Soma),
      Operando(0),
      Operador(Divisao),
    ]),
    Ok(0),
  )
  // *
  check.eq(avaliar_posfixa([Operador(Multiplicacao)]), Error(ExpressaoInvalida))
  // (3)
  check.eq(
    avaliar_posfixa([
      Agrupador(ParenteseAbertura),
      Operando(3),
      Agrupador(ParenteseFechamento),
    ]),
    Error(ExpressaoInvalida),
  )
}

// Realiza a operacao do *operador* entre *op1* e *op2*
pub fn realiza_operacao(valor1: Int, valor2: Int, operador: Operacao) -> Int {
  case operador {
    Soma -> valor1 + valor2
    Subtracao -> valor1 - valor2
    Multiplicacao -> valor1 * valor2
    Divisao -> valor1 / valor2
  }
}

// Desempilha dois elementos da *pilha*, retorna erro caso não consiga
pub fn desempilha_dois(pilha: List(Int)) -> Result(#(Int, Int, List(Int)), Erro) {
  case pilha {
    [valor1, valor2, ..resto] -> Ok(#(valor1, valor2, resto))
    _ -> Error(ExpressaoInvalida)
  }
}
