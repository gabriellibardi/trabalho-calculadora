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
import gleam/int
import gleam/result
import gleam/string
import sgleam/check

/// Conjunto de possíveis erros que podem ocorrer durante a execução do programa.
pub type Erro {
  CaractereInvalido
  ExpressaoInvalida
  DivisaoPorZero
}

/// Representa o operador de uma expressão.
pub type Operador {
  Soma
  Subtracao
  Multiplicacao
  Divisao
  ParenteseAbertura
  ParenteseFechamento
}

/// Representa o símbolo de uma expressão
pub type Simbolo {
  Operando(Int)
  Operador(Operador)
}

/// Representa a estrutura de uma pilha durante a montagem de uma expressão
pub type PilhaConversao {
  PilhaConversao(List(Simbolo), Boolean)
}

/// Converte uma *expressao_str* para uma lista de caracteres, desconsiderando espaços em branco.
pub fn converte_expressao_str(expressao_str: String) -> List(String) {
  string.split(expressao_str, "")
  |> list.filter(fn(s) {s != " "})
}

pub fn converte_expressao_str_examples() {
  check.eq(converte_expressao_str(""), [])
  check.eq(converte_expressao_str("2"), ["2"])
  check.eq(converte_expressao_str("(2 - 3)* 1"), ["(", "2", "-", "3", ")", "*", "1"])
}

/// Verifica se a lista de *caracteres* pode formar uma possível expressão, retornando a lista de 
/// entrada caso sejam ou um Erro caso contrário.
pub fn verifica_expressao(caracteres: List(String)) -> Result(List(String), Erro) {
  use l1 <- result.try(verifica_parenteses(caracteres))
  use l2 <- result.try(verifica_caracteres(caracteres))
  Ok(caracteres)
}

pub fn verifica_expressao_examples() {
  check.eq(verifica_expressao([]), Ok([]))
  check.eq(verifica_expressao(["9", "2", "-", "1", "0", "*", "(", "1", "1", "+", "2", "2", ")", "/", "1"]), Ok(["9", "2", "-", "1", "0", "*", "(", "1", "1", "+", "2", "2", ")", "/", "1"]))
  check.eq(verifica_expressao(["(", "5", "2", "-", "1", "4", ")", "*", ")", "9", "+", "2", ")"]), Error(ExpressaoInvalida))
  check.eq(verifica_expressao(["7", "1", "-", "a", "/", "2"]), Error(CaractereInvalido))
}

/// Verifica os *caracteres* de uma expressão possui os parênteses contados corretamente, retornando a
/// lista de entrada caso estejam ou um Erro caso contrário.
pub fn verifica_parenteses(caracteres: List(String)) -> Result(List(String), Erro) {
  case list.fold(caracteres, 0, fn(acc, c) { case acc < 0, c {True, _ -> acc False, "(" -> acc + 1 False, ")" -> acc - 1 False, _ -> acc}}) == 0 {
    True -> Ok(caracteres)
    False -> Error(ExpressaoInvalida)
  }
}

pub fn verifica_parenteses_examples() {
  check.eq(verifica_parenteses([]), Ok([]))
  check.eq(verifica_parenteses(["(", "2", "3", "-", "1", "*", "(", "7", "/", "9", ")", "-", "1", ")"]), Ok(["(", "2", "3", "-", "1", "*", "(", "7", "/", "9", ")", "-", "1", ")"]))
  check.eq(verifica_parenteses(["(", "1", "*", "1", "0", "(", "3", "*", "1", ")"]), Error(ExpressaoInvalida))
}

/// Verifica se a integridade dos *caracteres*, retornando a lista caso os caracteres sejam íntegros ou
/// um Erro caso contrário.
/// Um caractere é íntegro se ele é um possível operando (número de 0 a 9) ou um operador (parênteses ou
/// + - / *).
pub fn verifica_caracteres(caracteres: List(String)) -> Result(List(String), Erro) {
  list.try_map(caracteres, verifica_caractere)
}

pub fn verifica_caracteres_examples() {
  check.eq(verifica_caracteres([]), Ok([]))
  check.eq(verifica_caracteres(["(", "1", "+", "2", ")", "*", "3", "/", "(", "8", "-", "9", ")"]), Ok(["(", "1", "+", "2", ")", "*", "3", "/", "(", "8", "-", "9", ")"]))
  check.eq(verifica_caracteres(["9", "-", "2", "*", "a"]), Error(CaractereInvalido))
}

/// Verifica se o *caractere* é válido para uma possível expressão. Retorna um Erro caso
/// não seja.
pub fn verifica_caractere(caractere: String) -> Result(String, Erro) {
  case caractere, int.parse(caractere) {
    "/", _ -> Ok(caractere)
    "*", _ -> Ok(caractere)
    "-", _ -> Ok(caractere)
    "+", _ -> Ok(caractere)
    "(", _ -> Ok(caractere)
    ")", _ -> Ok(caractere)
    _, Ok(_) -> Ok(caractere)
    _, Error(_) -> Error(CaractereInvalido)
  }
}

pub fn verifica_caractere_examples() {
  check.eq(verifica_caractere(""), Error(CaractereInvalido))
  check.eq(verifica_caractere("a"), Error(CaractereInvalido))
  check.eq(verifica_caractere("2"), Ok("2"))
  check.eq(verifica_caractere("/"), Ok("/"))
  check.eq(verifica_caractere("*"), Ok("*"))
  check.eq(verifica_caractere("-"), Ok("-"))
  check.eq(verifica_caractere("+"), Ok("+"))
  check.eq(verifica_caractere("("), Ok("("))
  check.eq(verifica_caractere(")"), Ok(")"))
}

/// Converte uma lista de *caracteres* para uma expressão infixa, isto é, uma lista de símbolos.
/// Retorna um erro caso a estrutura da expressão seja inválida.
/// Requer que os parênteses já tenham sido verificados.
pub fn converte_expressao_infixa(caracteres: List(String)) -> Result(List(Simbolo), Erro) {
  converte_expressao_infixa_acc(caracteres, PilhaConversao("", True))
}

pub fn converte_expressao_infixa_examples() {
  check.eq(converte_expressao_infixa([]), Ok([]))
  check.eq(converte_expressao_infixa(["a", "/", "b"]), Error(CaractereInvalido))
  check.eq(converte_expressao_infixa(["4", "2", "*", "(", "1", "3", "/", "2", ")"]), Ok([Operando(42), Operador(Multiplicacao), Operador(ParenteseAbertura), Operando(13), Operador(Divisao), Operando(2), Operador(ParenteseFechamento)]))
  check.eq(converte_expressao_infixa(["-", "3", "2", "+", "3", "*", "(", "-", "2", "/", "1", ")"]), Ok([Operando(-32), Operador(Soma), Operando(3), Operador(Multiplicacao), Operador(ParenteseAbertura), Operando(-2), Operador(Divisao), Operando(1), Operador(ParenteseFechamento)]))
}

/// Auxiliar com o acumulador *pilha_conversao* da função 'converte_expressao_infixa'.
pub fn converte_expressao_infixa_acc(caracteres: List(String), pilha_conversao: PilhaConversao) -> Result(List(Simbolo), Erro) {
  case caracteres {
    [primeiro, ..resto] -> gerencia_conversao(primeiro, pilha_conversao, resto)
    [] -> case gerencia_conversao("", pilha_conversao, resto)
  }
}

pub fn converte_expressao_infixa_acc_examples() {
  check.eq(converte_expressao_infixa_acc(["-", "1", "2", "*", "7", "+", "(", "-", "2", "/", "2", ")", "*", "(", "4", "-", "1", ")"], PilhaConversao("", True)), Ok([Operando(-12), Operador(Multiplicacao), Operando(7), Operador(Soma), Operador(ParenteseAbertura), Operando(-2), Operador(Divisao), Operando(2), Operador(ParenteseFechamento), Operador(Multiplicacao), Operador(ParenteseAbertura), Operando(4), Operador(Subtracao), Operando(1), Operador(ParenteseFechamento)]))
  check.eq(converte_expressao_infixa_acc([], PilhaConversao("10", False)), Ok([Operando(10)]))
}

/// Realiza o gerenciamento da pilha e da lista de saída durante a conversão de uma lista de caracteres
/// formada pelo primeiro *caractere* e o *resto*, e uma *pilha_conversao*, retornando uma expressão ou
/// um Erro caso a conversão seja inválida.
pub fn gerencia_conversao(caractere: String, pilha_conversao: PilhaConversao, resto: List(String)) -> Result(List(Simbolo), Erro) {
  todo
}

pub fn gerencia_conversao_examples() {
  check.eq(gerencia_conversao("+", PilhaConversao([Operando(2)], False), ["1", "-", "2"]), Ok[Operando(2), Operador(Soma), Operando(1), Operador(Subtracao), Operando(2)])
  check.eq(gerencia_conversao("*", PilhaConversao([Operador(ParenteseFechamento)], False), ["7", "1"]), Ok[Operador(ParenteseFechamento), Operador(Multiplicacao), Operando(71)])
  check.eq(gerencia_conversao("/", PilhaConversao([], False), ["5"]), Error(ExpressaoInvalida))

  check.eq(gerencia_conversao("-", PilhaConversao([], True), ["1", "+", "2"]), Ok[Operando(-1), Operador(Soma), Operando(2)])
  check.eq(gerencia_conversao("-", PilhaConversao([Operador(ParenteseAbertura)], True), ["1", "/", "2", ")"]), Ok[Operador(ParenteseAbertura), Operando(-1), Operador(Divisao), Operando(2), Operador(ParenteseFechamento)])
  check.eq(gerencia_conversao("-", PilhaConversao([], ), []), Ok[])
  check.eq(gerencia_conversao("-", PilhaConversao([], ), []), Ok[])

  check.eq(gerencia_conversao("0", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("9", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("4", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("0", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("1", PilhaConversao(), []), Ok[])
  
  check.eq(gerencia_conversao("(", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("(", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("(", PilhaConversao(), []), Ok[])

  check.eq(gerencia_conversao(")", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao(")", PilhaConversao(), []), Ok[])

  check.eq(gerencia_conversao("", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("", PilhaConversao(), []), Ok[])
  check.eq(gerencia_conversao("", PilhaConversao(), []), Ok[])
}

/// Incrementa o *operando* adicionando o *caractere* à direita.
pub fn incrementa_operando(operando: Int, caractere: String) -> Result(Operando, Erro) {
  case int.parse(int.to_string(operando) <> caractere) {
    Ok(num) -> Operando(num)
    Error(_) -> Error(CaractereInvalido)
  }
}

pub fn incrementa_operando_examples() {
  check.eq(incrementa_operando(3, "2"), Ok(Operando(32)))
  check.eq(incrementa_operando(-1, "0"), Ok(Operando(-10)))
  check.eq(incrementa_operando(1, "a"), Error(CaractereInvalido))
}

/// Converte uma *expressao* na forma infixa para sua forma pós-fixa. Retorna um Erro caso a estrutura da
/// expressão seja inválida.
pub fn converte_infixa(expressao: List(Simbolo)) -> Result(List(Simbolo), Erro) {
  converte_infixa_acc(expressao, [])
}

pub fn converte_infixa_examples() {
  check.eq(
    converte_infixa([
      Operando(15),
      Operador(Multiplicacao),
      Operador(ParenteseAbertura),
      Operando(1),
      Operador(ParenteseFechamento),
      Operador(ParenteseFechamento),
    ]),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_infixa([
      Operando(2),
      Operador(Soma),
      Operador(ParenteseAbertura),
      Operando(1),
      Operador(ParenteseFechamento),
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
pub fn converte_infixa_acc(
  expressao: List(Simbolo),
  pilha: List(Operador),
) -> Result(List(Simbolo), Erro) {
  case expressao {
    [simbolo, ..resto] ->
      case simbolo {
        Operando(_) ->
          result.try(converte_infixa_acc(resto, pilha), fn(l) {
            Ok([simbolo, ..l])
          })
        Operador(ParenteseAbertura) ->
          result.try(
            converte_infixa_acc(resto, [ParenteseAbertura, ..pilha]),
            fn(l) { Ok(l) },
          )
        Operador(ParenteseFechamento) ->
          result.try(trata_parenteses(resto, pilha), fn(l) { Ok(l) })
        Operador(oper) ->
          result.try(trata_operador(oper, resto, pilha), fn(l) { Ok(l) })
      }
    [] -> result.try(converte_pilha(pilha), fn(l) { Ok(l) })
  }
}

pub fn converte_infixa_acc_examples() {
  check.eq(converte_infixa_acc([], []), Ok([]))
  check.eq(
    converte_infixa_acc(
      [
        Operando(15),
        Operador(Divisao),
        Operando(12),
        Operador(ParenteseFechamento),
      ],
      [],
    ),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_infixa_acc(
      [Operador(ParenteseAbertura), Operando(10), Operador(Soma), Operando(5)],
      [],
    ),
    Error(ExpressaoInvalida),
  )
  check.eq(
    converte_infixa_acc([Operando(10), Operador(Subtracao), Operando(4)], []),
    Ok([Operando(10), Operando(4), Operador(Subtracao)]),
  )
  check.eq(
    converte_infixa_acc(
      [Operando(5), Operador(Soma), Operando(6), Operador(Divisao), Operando(4)],
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
    converte_infixa_acc(
      [
        Operando(1),
        Operador(Multiplicacao),
        Operador(ParenteseAbertura),
        Operando(5),
        Operador(Soma),
        Operando(1),
        Operador(ParenteseFechamento),
      ],
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
    converte_infixa_acc(
      [
        Operando(4),
        Operador(Divisao),
        Operando(2),
        Operador(Multiplicacao),
        Operador(ParenteseAbertura),
        Operando(1),
        Operador(Subtracao),
        Operando(3),
        Operador(ParenteseFechamento),
        Operador(Soma),
        Operador(ParenteseAbertura),
        Operando(1),
        Operador(Divisao),
        Operando(3),
        Operador(ParenteseFechamento),
      ],
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
/// para a forma pós-fixa. Retorna um Erro caso a estrutura da expressão seja inválida.
pub fn trata_parenteses(
  resto_expressao: List(Simbolo),
  pilha: List(Operador),
) -> Result(List(Simbolo), Erro) {
  case pilha {
    [operador_empilhado, ..resto_pilha] ->
      case operador_empilhado {
        ParenteseAbertura ->
          result.try(converte_infixa_acc(resto_expressao, resto_pilha), fn(l) {
            Ok(l)
          })
        _ ->
          result.try(trata_parenteses(resto_expressao, resto_pilha), fn(l) {
            Ok([Operador(operador_empilhado), ..l])
          })
      }
    [] -> Error(ExpressaoInvalida)
  }
}

pub fn trata_parenteses_examples() {
  check.eq(
    trata_parenteses([Operador(Multiplicacao), Operando(9)], [
      Soma,
      ParenteseAbertura,
    ]),
    Ok([Operador(Soma), Operando(9), Operador(Multiplicacao)]),
  )
  check.eq(
    trata_parenteses([Operador(Soma), Operando(1)], [Subtracao]),
    Error(ExpressaoInvalida),
  )
}

/// Trata o gerenciamento do *operador* utilizando a *pilha* no processo de conversão do *resto_expressao*
/// para a forma pós-fixa. Retorna um Erro caso a estrutura da expressão seja inválida.
pub fn trata_operador(
  operador: Operador,
  resto_expressao: List(Simbolo),
  pilha: List(Operador),
) -> Result(List(Simbolo), Erro) {
  case pilha {
    [operador_empilhado, ..resto_pilha] ->
      case
        precedencia_operador(operador_empilhado)
        >= precedencia_operador(operador)
      {
        True ->
          result.try(
            converte_infixa_acc(
              [Operador(operador), ..resto_expressao],
              resto_pilha,
            ),
            fn(l) { Ok([Operador(operador_empilhado), ..l]) },
          )
        False ->
          result.try(
            converte_infixa_acc(resto_expressao, [operador, ..pilha]),
            fn(l) { Ok(l) },
          )
      }
    [] ->
      result.try(converte_infixa_acc(resto_expressao, [operador]), fn(l) {
        Ok(l)
      })
  }
}

pub fn trata_operador_examples() {
  check.eq(
    trata_operador(Divisao, [Operando(3)], [Multiplicacao]),
    Ok([Operador(Multiplicacao), Operando(3), Operador(Divisao)]),
  )
  check.eq(
    trata_operador(Multiplicacao, [Operando(5)], [Soma]),
    Ok([Operando(5), Operador(Multiplicacao), Operador(Soma)]),
  )
  check.eq(
    trata_operador(Subtracao, [Operando(4)], []),
    Ok([Operando(4), Operador(Subtracao)]),
  )
  check.eq(
    trata_operador(
      Soma,
      [
        Operando(4),
        Operador(ParenteseFechamento),
        Operador(ParenteseFechamento),
      ],
      [ParenteseAbertura],
    ),
    Error(ExpressaoInvalida),
  )
}

/// Verifica o valor de precedência de um *operador*, retornando 2 caso seja Multiplicacao ou Divisao, 1
/// caso seja Soma ou Subtracao e 0 caso não seja nenhuma das situações anteriores.
pub fn precedencia_operador(operador: Operador) -> Int {
  case operador {
    Multiplicacao -> 2
    Divisao -> 2
    Soma -> 1
    Subtracao -> 1
    _ -> 0
  }
}

pub fn precedencia_operador_examples() {
  check.eq(precedencia_operador(Multiplicacao), 2)
  check.eq(precedencia_operador(Divisao), 2)
  check.eq(precedencia_operador(Soma), 1)
  check.eq(precedencia_operador(Subtracao), 1)
  check.eq(precedencia_operador(ParenteseAbertura), 0)
  check.eq(precedencia_operador(ParenteseFechamento), 0)
}

/// Converte a *pilha* de Operadores para uma pilha de Simbolos. Retorna um erro caso o restante da pilha
/// possua parênteses pendentes.
pub fn converte_pilha(pilha: List(Operador)) -> Result(List(Simbolo), Erro) {
  list.try_map(pilha, fn(op) {
    case op {
      ParenteseAbertura -> Error(ExpressaoInvalida)
      ParenteseFechamento -> Error(ExpressaoInvalida)
      _ -> Ok(Operador(op))
    }
  })
}

pub fn converte_pilha_examples() {
  check.eq(converte_pilha([]), Ok([]))
  check.eq(
    converte_pilha([Multiplicacao, Subtracao]),
    Ok([Operador(Multiplicacao), Operador(Subtracao)]),
  )
  check.eq(
    converte_pilha([Soma, ParenteseFechamento]),
    Error(ExpressaoInvalida),
  )
}