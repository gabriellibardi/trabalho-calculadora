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

import gleam/int
import gleam/list
import gleam/result
import gleam/string
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

/// Representa a estrutura de uma pilha durante a montagem de uma expressão
pub type PilhaConversao {
  PilhaVazia(Bool)
  PilhaConversao(Simbolo, Bool)
}

pub fn main(expressao: String) -> Result(Int, Erro) {
  let expressao = converte_expressao_str(expressao)
  use expressao_infixa <- result.try(converte_expressao_infixa(expressao))
  use expressao_posfixa <- result.try(converte_posfixa(expressao_infixa))
  use resultado <- result.try(avaliar_posfixa(expressao_posfixa))
  Ok(resultado)
}

pub fn main_examples() {
  check.eq(main("2 + 2"), Ok(4))
  check.eq(main("10 - 3"), Ok(7))
  check.eq(main("4 * 5"), Ok(20))
  check.eq(main("20 / 4"), Ok(5))
  check.eq(main("1 + 2 * 3"), Ok(7))
  check.eq(main("(1 + 2) * 3"), Ok(9))
  check.eq(main("10 / 2 + 3"), Ok(8))
  check.eq(main("10 / (2 + 3)"), Ok(2))
  check.eq(main("   5 +  3   "), Ok(8))
  check.eq(main("7 * (2 + 3) "), Ok(35))
  check.eq(main("1 + 2 * (3 + 4) - 5 / (2 + 3)"), Ok(14))
  check.eq(main("(10 - 5) * ((3 + 2) / 5)"), Ok(5))
  check.eq(main("((1 + 1) * (2 + 2)) / 2"), Ok(4))
  check.eq(main("1000000 + 2000000"), Ok(3_000_000))
  check.eq(main("123456 * 654321"), Ok(80_779_853_376))
  check.eq(main("2 + "), Error(ExpressaoInvalida))
  check.eq(main("4 * (3 - )"), Error(ExpressaoInvalida))
  check.eq(main("(2 + 3"), Error(ExpressaoInvalida))
  check.eq(main("hello + world"), Error(CaractereInvalido))
  check.eq(main(""), Error(ExpressaoInvalida))
}

// CONVERSÃO DA STRING EM UMA LISTA DE CARACTERES ---------------------------------------------------------------------

/// Converte uma *expressao_str* para uma lista de caracteres, desconsiderando espaços em branco.
pub fn converte_expressao_str(expressao_str: String) -> List(String) {
  string.split(expressao_str, "")
  |> list.filter(fn(s) { s != " " })
}

pub fn converte_expressao_str_examples() {
  check.eq(converte_expressao_str(""), [])
  check.eq(converte_expressao_str("2"), ["2"])
  check.eq(converte_expressao_str("(2 - 3)* 1"), [
    "(", "2", "-", "3", ")", "*", "1",
  ])
}

// CONVERSÃO PARA EXPRESSÃO INFIXA -----------------------------------------------------------------------------------

/// Converte uma lista de *caracteres* para uma expressão infixa, isto é, uma lista de símbolos.
/// Retorna um erro caso a estrutura da expressão seja inválida.
/// Requer que os parênteses já tenham sido verificados.
pub fn converte_expressao_infixa(
  caracteres: List(String),
) -> Result(List(Simbolo), Erro) {
  converte_expressao_infixa_acc(caracteres, PilhaVazia(True))
}

pub fn converte_expressao_infixa_examples() {
  check.eq(converte_expressao_infixa([]), Ok([]))
  check.eq(converte_expressao_infixa(["a", "/", "b"]), Error(CaractereInvalido))
  check.eq(
    converte_expressao_infixa(["4", "2", "*", "(", "1", "3", "/", "2", ")"]),
    Ok([
      Operando(42),
      Operador(Multiplicacao),
      Agrupador(ParenteseAbertura),
      Operando(13),
      Operador(Divisao),
      Operando(2),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    converte_expressao_infixa([
      "-", "3", "2", "+", "3", "*", "(", "-", "2", "/", "1", ")",
    ]),
    Ok([
      Operando(-32),
      Operador(Soma),
      Operando(3),
      Operador(Multiplicacao),
      Agrupador(ParenteseAbertura),
      Operando(-2),
      Operador(Divisao),
      Operando(1),
      Agrupador(ParenteseFechamento),
    ]),
  )
}

/// Auxiliar com o acumulador *pilha_conversao* da função 'converte_expressao_infixa'.
pub fn converte_expressao_infixa_acc(
  caracteres: List(String),
  pilha_conversao: PilhaConversao,
) -> Result(List(Simbolo), Erro) {
  case caracteres {
    [primeiro, ..resto] -> gerencia_conversao(primeiro, pilha_conversao, resto)
    [] -> gerencia_conversao("", pilha_conversao, [])
  }
}

pub fn converte_expressao_infixa_acc_examples() {
  check.eq(
    converte_expressao_infixa_acc(
      [
        "-", "1", "2", "*", "7", "+", "(", "-", "2", "/", "2", ")", "*", "(",
        "4", "-", "1", ")",
      ],
      PilhaVazia(True),
    ),
    Ok([
      Operando(-12),
      Operador(Multiplicacao),
      Operando(7),
      Operador(Soma),
      Agrupador(ParenteseAbertura),
      Operando(-2),
      Operador(Divisao),
      Operando(2),
      Agrupador(ParenteseFechamento),
      Operador(Multiplicacao),
      Agrupador(ParenteseAbertura),
      Operando(4),
      Operador(Subtracao),
      Operando(1),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    converte_expressao_infixa_acc([], PilhaConversao(Operando(10), False)),
    Ok([Operando(10)]),
  )
}

/// Realiza o gerenciamento da pilha e da lista de saída durante a conversão de uma lista de caracteres
/// formada pelo primeiro *caractere* e o *resto*, e uma *pilha_conversao*, retornando uma expressão ou
/// um Erro caso a conversão seja inválida.
pub fn gerencia_conversao(
  caractere: String,
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case caractere {
    c if c == "+" || c == "*" || c == "/" ->
      processa_som_mul_div(c, pilha_conversao, resto)
    "-" -> processa_sub(pilha_conversao, resto)
    n
      if n == "0"
      || n == "1"
      || n == "2"
      || n == "3"
      || n == "4"
      || n == "5"
      || n == "6"
      || n == "7"
      || n == "8"
      || n == "9"
    -> processa_num(n, pilha_conversao, resto)
    "(" -> processa_pa(pilha_conversao, resto)
    ")" -> processa_pf(pilha_conversao, resto)
    "" -> processa_fim(pilha_conversao)
    _ -> Error(CaractereInvalido)
  }
}

pub fn gerencia_conversao_examples() {
  check.eq(
    gerencia_conversao(
      "/",
      PilhaConversao(Agrupador(ParenteseFechamento), False),
      ["7", "-", "2"],
    ),
    Ok([
      Agrupador(ParenteseFechamento),
      Operador(Divisao),
      Operando(7),
      Operador(Subtracao),
      Operando(2),
    ]),
  )
  check.eq(
    gerencia_conversao(
      "-",
      PilhaConversao(Agrupador(ParenteseFechamento), False),
      ["9", "*", "3"],
    ),
    Ok([
      Agrupador(ParenteseFechamento),
      Operador(Subtracao),
      Operando(9),
      Operador(Multiplicacao),
      Operando(3),
    ]),
  )
  check.eq(
    gerencia_conversao(
      "2",
      PilhaConversao(Agrupador(ParenteseFechamento), False),
      ["4", "*", "2"],
    ),
    Error(ExpressaoInvalida),
  )
  check.eq(
    gerencia_conversao("(", PilhaConversao(Operador(Soma), False), [
      "1", "/", "1", ")",
    ]),
    Ok([
      Operador(Soma),
      Agrupador(ParenteseAbertura),
      Operando(1),
      Operador(Divisao),
      Operando(1),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    gerencia_conversao(")", PilhaConversao(Operando(21), False), ["-", "9", "1"]),
    Ok([
      Operando(21),
      Agrupador(ParenteseFechamento),
      Operador(Subtracao),
      Operando(91),
    ]),
  )
  check.eq(gerencia_conversao("", PilhaVazia(False), []), Ok([]))
}

/// Realiza o processamento da entrada sendo Soma, Multiplicação ou Divisão em uma conversão de uma lista
/// de caracteres para uma expressão infixa, utilizando o *caractere*, a *pilha_conversao* e o *resto* da
/// lista.
pub fn processa_som_mul_div(
  caractere: String,
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao, caractere {
    PilhaConversao(Operando(num), _), "+" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Soma), False),
      ))
      Ok([Operando(num), ..exp])
    }
    PilhaConversao(Operando(num), _), "*" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Multiplicacao), False),
      ))
      Ok([Operando(num), ..exp])
    }
    PilhaConversao(Operando(num), _), "/" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Divisao), False),
      ))
      Ok([Operando(num), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseFechamento), _), "+" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Soma), False),
      ))
      Ok([Agrupador(ParenteseFechamento), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseFechamento), _), "*" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Multiplicacao), False),
      ))
      Ok([Agrupador(ParenteseFechamento), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseFechamento), _), "/" -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Divisao), False),
      ))
      Ok([Agrupador(ParenteseFechamento), ..exp])
    }
    _, _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_som_mul_div_examples() {
  check.eq(
    processa_som_mul_div("+", PilhaConversao(Operando(2), False), [
      "1", "-", "2",
    ]),
    Ok([
      Operando(2),
      Operador(Soma),
      Operando(1),
      Operador(Subtracao),
      Operando(2),
    ]),
  )
  check.eq(
    processa_som_mul_div(
      "*",
      PilhaConversao(Agrupador(ParenteseFechamento), False),
      ["7", "1"],
    ),
    Ok([Agrupador(ParenteseFechamento), Operador(Multiplicacao), Operando(71)]),
  )
  check.eq(
    processa_som_mul_div("/", PilhaVazia(False), ["5"]),
    Error(ExpressaoInvalida),
  )
}

/// Realiza o processamento da entrada sendo Subtração em uma conversão de uma lista de caracteres para uma
/// expressão infixa, utilizando a *pilha_conversao* e o *resto* da lista.
pub fn processa_sub(
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao {
    PilhaVazia(True) ->
      converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Subtracao), False),
      )
    PilhaConversao(Agrupador(ParenteseAbertura), _) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operador(Subtracao), False),
      ))
      Ok([Agrupador(ParenteseAbertura), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseFechamento), _) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaVazia(False),
      ))
      Ok([Agrupador(ParenteseFechamento), Operador(Subtracao), ..exp])
    }
    PilhaConversao(Operando(num), _) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaVazia(False),
      ))
      Ok([Operando(num), Operador(Subtracao), ..exp])
    }
    _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_sub_examples() {
  check.eq(
    processa_sub(PilhaVazia(True), ["1", "+", "2"]),
    Ok([Operando(-1), Operador(Soma), Operando(2)]),
  )
  check.eq(
    processa_sub(PilhaConversao(Agrupador(ParenteseAbertura), True), [
      "1", "/", "2", ")",
    ]),
    Ok([
      Agrupador(ParenteseAbertura),
      Operando(-1),
      Operador(Divisao),
      Operando(2),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    processa_sub(PilhaConversao(Agrupador(ParenteseFechamento), False), [
      "9", "*", "3",
    ]),
    Ok([
      Agrupador(ParenteseFechamento),
      Operador(Subtracao),
      Operando(9),
      Operador(Multiplicacao),
      Operando(3),
    ]),
  )
  check.eq(
    processa_sub(PilhaConversao(Operando(12), False), ["9"]),
    Ok([Operando(12), Operador(Subtracao), Operando(9)]),
  )
  check.eq(processa_sub(PilhaVazia(False), ["9"]), Error(ExpressaoInvalida))
}

pub fn processa_num(
  numero: String,
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao, int.parse(numero) {
    PilhaVazia(_), Ok(num) ->
      converte_expressao_infixa_acc(resto, PilhaConversao(Operando(num), False))
    PilhaConversao(Operador(Subtracao), _), Ok(num) ->
      converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operando(-num), False),
      )
    PilhaConversao(Operando(num), _), _ -> {
      use opconv <- result.try(incrementa_operando(num, numero))
      converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operando(opconv), False),
      )
    }
    PilhaConversao(Operador(op), _), Ok(num)
      if op == Soma || op == Divisao || op == Multiplicacao
    -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operando(num), False),
      ))
      Ok([Operador(op), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseAbertura), _), Ok(num) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Operando(num), False),
      ))
      Ok([Agrupador(ParenteseAbertura), ..exp])
    }
    _, _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_num_examples() {
  check.eq(
    processa_num("0", PilhaVazia(False), ["-", "4"]),
    Ok([Operando(0), Operador(Subtracao), Operando(4)]),
  )
  check.eq(
    processa_num("9", PilhaConversao(Operador(Subtracao), False), [
      "1", "/", "4",
    ]),
    Ok([Operando(-91), Operador(Divisao), Operando(4)]),
  )
  check.eq(
    processa_num("4", PilhaConversao(Operando(-1), False), ["*", "2"]),
    Ok([Operando(-14), Operador(Multiplicacao), Operando(2)]),
  )
  check.eq(
    processa_num("0", PilhaConversao(Agrupador(ParenteseAbertura), True), [
      "1", "-", "1", ")",
    ]),
    Ok([
      Agrupador(ParenteseAbertura),
      Operando(1),
      Operador(Subtracao),
      Operando(1),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    processa_num("1", PilhaConversao(Agrupador(ParenteseFechamento), False), [
      "+", "4",
    ]),
    Error(ExpressaoInvalida),
  )
}

/// Incrementa o *operando* adicionando o *caractere* à direita.
pub fn incrementa_operando(
  operando: Int,
  caractere: String,
) -> Result(Int, Erro) {
  case int.parse(int.to_string(operando) <> caractere) {
    Ok(num) -> Ok(num)
    Error(_) -> Error(CaractereInvalido)
  }
}

pub fn incrementa_operando_examples() {
  check.eq(incrementa_operando(3, "2"), Ok(32))
  check.eq(incrementa_operando(-1, "0"), Ok(-10))
  check.eq(incrementa_operando(1, "a"), Error(CaractereInvalido))
}

/// /// Realiza o processamento da entrada sendo uma abertura de parênteses em uma conversão de uma lista de
/// caracteres para uma expressão infixa, utilizando a *pilha_conversao* e o *resto* da lista.
pub fn processa_pa(
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao {
    PilhaConversao(Operador(op), _)
      if op == Soma || op == Multiplicacao || op == Divisao
    -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Agrupador(ParenteseAbertura), True),
      ))
      Ok([Operador(op), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseAbertura), _) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        pilha_conversao,
      ))
      Ok([Agrupador(ParenteseAbertura), ..exp])
    }
    PilhaVazia(_) ->
      converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Agrupador(ParenteseAbertura), True),
      )
    _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_pa_examples() {
  check.eq(
    processa_pa(PilhaConversao(Operador(Soma), False), [
      "4", "1", "-", "2", "1", ")",
    ]),
    Ok([
      Operador(Soma),
      Agrupador(ParenteseAbertura),
      Operando(41),
      Operador(Subtracao),
      Operando(21),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    processa_pa(PilhaVazia(False), ["2", "-", "1", ")"]),
    Ok([
      Agrupador(ParenteseAbertura),
      Operando(2),
      Operador(Subtracao),
      Operando(1),
      Agrupador(ParenteseFechamento),
    ]),
  )
  check.eq(
    processa_pa(PilhaConversao(Operador(Subtracao), False), ["0", "*", "9", ")"]),
    Error(ExpressaoInvalida),
  )
}

/// Realiza o processamento da entrada sendo um fechamento de parênteses em uma conversão de uma lista de
/// caracteres para uma expressão infixa, utilizando a *pilha_conversao* e o *resto* da lista.
pub fn processa_pf(
  pilha_conversao: PilhaConversao,
  resto: List(String),
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao {
    PilhaConversao(Operando(num), False) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        PilhaConversao(Agrupador(ParenteseFechamento), False),
      ))
      Ok([Operando(num), ..exp])
    }
    PilhaConversao(Agrupador(ParenteseFechamento), _) -> {
      use exp <- result.try(converte_expressao_infixa_acc(
        resto,
        pilha_conversao,
      ))
      Ok([Agrupador(ParenteseFechamento), ..exp])
    }
    _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_pf_examples() {
  check.eq(
    processa_pf(PilhaConversao(Operando(4), False), ["+", "4"]),
    Ok([
      Operando(4),
      Agrupador(ParenteseFechamento),
      Operador(Soma),
      Operando(4),
    ]),
  )
  check.eq(
    processa_pf(PilhaVazia(True), ["5", "/", "5"]),
    Error(ExpressaoInvalida),
  )
}

/// Realiza o processamento ao fim da conversão de uma lista de caracteres para uma experessão infixa,
/// utilizando a *pilha_conversao*.
pub fn processa_fim(
  pilha_conversao: PilhaConversao,
) -> Result(List(Simbolo), Erro) {
  case pilha_conversao {
    PilhaVazia(_) -> Ok([])
    PilhaConversao(Agrupador(ParenteseFechamento), _) ->
      Ok([Agrupador(ParenteseFechamento)])
    PilhaConversao(Operando(num), _) -> Ok([Operando(num)])
    _ -> Error(ExpressaoInvalida)
  }
}

pub fn processa_fim_examples() {
  check.eq(
    processa_fim(PilhaConversao(Agrupador(ParenteseFechamento), False)),
    Ok([Agrupador(ParenteseFechamento)]),
  )
  check.eq(
    processa_fim(PilhaConversao(Operando(51), False)),
    Ok([Operando(51)]),
  )
  check.eq(processa_fim(PilhaVazia(False)), Ok([]))
  check.eq(
    processa_fim(PilhaConversao(Operador(Multiplicacao), False)),
    Error(ExpressaoInvalida),
  )
}

// CONVERSÃO DA EXPRESSÃO PARA SUA FORMA PÓS-FIXA --------------------------------------------------------------------

/// Converte uma *expressao* na forma infixa para sua forma pós-fixa. Retorna um Erro caso a estrutura da
/// expressão seja inválida.
pub fn converte_posfixa(expressao: List(Simbolo)) -> Result(List(Simbolo), Erro) {
  converte_posfixa_acc(expressao, [], [])
}

pub fn converte_posfixa_examples() {
  check.eq(
    converte_posfixa([
      Operando(15),
      Operador(Multiplicacao),
      Agrupador(ParenteseAbertura),
      Operando(1),
      Agrupador(ParenteseFechamento),
      Agrupador(ParenteseFechamento),
    ]),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_posfixa([
      Operando(2),
      Operador(Soma),
      Agrupador(ParenteseAbertura),
      Operando(1),
      Agrupador(ParenteseFechamento),
      Operador(Multiplicacao),
      Operando(7),
    ]),
    Ok([
      Operando(2),
      Operando(1),
      Operando(7),
      Operador(Multiplicacao),
      Operador(Soma),
    ]),
  )
}

/// Converte uma *expressao* na forma infixa para sua forma pós-fixa, utilizando a *pilha* como acumulador.
/// Retorna um Erro caso a estrutura da expressão seja inválida.
pub fn converte_posfixa_acc(
  expressao: List(Simbolo),
  pilha: List(Simbolo),
  saida: List(Simbolo),
) -> Result(List(Simbolo), Erro) {
  case expressao {
    [simbolo, ..resto] ->
      case simbolo {
        Operando(op) ->
          converte_posfixa_acc(resto, pilha, list.append(saida, [Operando(op)]))
        Agrupador(ParenteseAbertura) ->
          converte_posfixa_acc(
            resto,
            [Agrupador(ParenteseAbertura), ..pilha],
            saida,
          )
        Agrupador(ParenteseFechamento) -> trata_parenteses(resto, pilha, saida)
        Operador(oper) -> trata_operador(Operador(oper), resto, pilha, saida)
      }
    [] -> converte_pilha(pilha, saida)
  }
}

pub fn converte_posfixa_acc_examples() {
  check.eq(converte_posfixa_acc([], [], []), Ok([]))
  check.eq(
    converte_posfixa_acc(
      [
        Operando(15),
        Operador(Divisao),
        Operando(12),
        Agrupador(ParenteseFechamento),
      ],
      [],
      [],
    ),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_posfixa_acc(
      [Agrupador(ParenteseAbertura), Operando(10), Operador(Soma), Operando(5)],
      [],
      [],
    ),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_posfixa_acc(
      [Operando(10), Operador(Subtracao), Operando(4)],
      [],
      [],
    ),
    Ok([Operando(10), Operando(4), Operador(Subtracao)]),
  )
  check.eq(
    converte_posfixa_acc(
      [Operando(5), Operador(Soma), Operando(6), Operador(Divisao), Operando(4)],
      [],
      [],
    ),
    Ok([
      Operando(5),
      Operando(6),
      Operando(4),
      Operador(Divisao),
      Operador(Soma),
    ]),
  )
  check.eq(
    converte_posfixa_acc(
      [
        Operando(1),
        Operador(Multiplicacao),
        Agrupador(ParenteseAbertura),
        Operando(5),
        Operador(Soma),
        Operando(1),
        Agrupador(ParenteseFechamento),
      ],
      [],
      [],
    ),
    Ok([
      Operando(1),
      Operando(5),
      Operando(1),
      Operador(Soma),
      Operador(Multiplicacao),
    ]),
  )
  check.eq(
    converte_posfixa_acc(
      [
        Operando(4),
        Operador(Divisao),
        Operando(2),
        Operador(Multiplicacao),
        Agrupador(ParenteseAbertura),
        Operando(1),
        Operador(Subtracao),
        Operando(3),
        Agrupador(ParenteseFechamento),
        Operador(Soma),
        Agrupador(ParenteseAbertura),
        Operando(1),
        Operador(Divisao),
        Operando(3),
        Agrupador(ParenteseFechamento),
      ],
      [],
      [],
    ),
    Ok([
      Operando(4),
      Operando(2),
      Operador(Divisao),
      Operando(1),
      Operando(3),
      Operador(Subtracao),
      Operador(Multiplicacao),
      Operando(1),
      Operando(3),
      Operador(Divisao),
      Operador(Soma),
    ]),
  )
}

/// Trata o fechamento de parênteses utilizando a *pilha* no processo de conversão do *resto_expressao*
fn trata_parenteses(
  resto: List(Simbolo),
  pilha: List(Simbolo),
  saida: List(Simbolo),
) -> Result(List(Simbolo), Erro) {
  case pilha {
    [Agrupador(ParenteseAbertura), ..nova_pilha] ->
      converte_posfixa_acc(resto, nova_pilha, saida)
    [Agrupador(ParenteseFechamento), ..] -> Error(ExpressaoInvalida)
    [operador, ..nova_pilha] ->
      trata_parenteses(resto, nova_pilha, list.append(saida, [operador]))
    [] -> Error(ExpressaoInvalida)
  }
}

/// Trata o gerenciamento do *operador* utilizando a *pilha* no processo de conversão do *resto_expressao*
/// para a forma pós-fixa. Retorna um Erro caso a estrutura da expressão seja inválida.
fn trata_operador(
  operador: Simbolo,
  resto: List(Simbolo),
  pilha: List(Simbolo),
  saida: List(Simbolo),
) -> Result(List(Simbolo), Erro) {
  case pilha {
    [oper, ..resto_pilha] ->
      case precedencia_simbolo(oper) >= precedencia_simbolo(operador) {
        True ->
          converte_posfixa_acc(
            resto,
            [operador, ..resto_pilha],
            list.append(saida, [oper]),
          )
        False -> converte_posfixa_acc(resto, [operador, ..pilha], saida)
      }
    [] -> converte_posfixa_acc(resto, [operador, ..pilha], saida)
  }
}

/// Verifica o valor de precedência de um *Simbolo*, retornando 2 caso seja Multiplicacao ou Divisao, 1
/// caso seja Soma ou Subtracao e 0 caso não seja nenhuma das situações anteriores.
pub fn precedencia_simbolo(simbolo: Simbolo) -> Int {
  case simbolo {
    Operador(Multiplicacao) -> 2
    Operador(Divisao) -> 2
    Operador(Soma) -> 1
    Operador(Subtracao) -> 1
    _ -> 0
  }
}

pub fn precedencia_simbolo_examples() {
  check.eq(precedencia_simbolo(Operador(Multiplicacao)), 2)
  check.eq(precedencia_simbolo(Operador(Divisao)), 2)
  check.eq(precedencia_simbolo(Operador(Soma)), 1)
  check.eq(precedencia_simbolo(Operador(Subtracao)), 1)
  check.eq(precedencia_simbolo(Agrupador(ParenteseFechamento)), 0)
  check.eq(precedencia_simbolo(Agrupador(ParenteseAbertura)), 0)
}

/// Converte a *pilha* de Operadores para uma pilha de Simbolos. Retorna um erro caso o restante da pilha
/// possua parênteses pendentes.
fn converte_pilha(
  pilha: List(Simbolo),
  saida: List(Simbolo),
) -> Result(List(Simbolo), Erro) {
  case pilha {
    [] -> Ok(saida)
    [Operador(op), ..resto] ->
      converte_pilha(resto, list.append(saida, [Operador(op)]))
    _ -> Error(ExpressaoInvalida)
  }
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
