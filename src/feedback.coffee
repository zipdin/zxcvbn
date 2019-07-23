scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Use algumas palavras, evite frases comuns."
      "Não há necessidade de usar símbolos, dígitos ou letras maiúsculas."
    ]

  get_feedback: (score, sequence) ->
    # starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 'Adicione uma ou duas palavra. As palavras incomuns são melhores.'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'As digitações em linha são fáceis de adivinhar. Ex.: QWERTY.'
        else
          'Padrões de teclado curtos são fáceis de adivinhar.'
        warning: warning
        suggestions: [
          'Use um padrão de digitação maior com mais voltas.'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Use um padrão de digitação maior com mais voltas.'
        else
          'Repetições como “abcabcabc” são apenas um pouco mais difíceis de adivinhar que “abc”.'
        warning: warning
        suggestions: [
          'Evite palavras e caracteres repetidos.'
        ]

      when 'sequence'
        warning: "Anos, datas e repetições como “aaa” são fáceis de adivinhar."
        suggestions: [
          'Avoid sequences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Os últimos anos são fáceis de adivinhar"
          suggestions: [
            'Evite anos recentes'
            'Evite anos associados a você'
          ]

      when 'date'
        warning: "As datas costumam ser fáceis de adivinhar"
        suggestions: [
          'Evite datas e anos associados a você'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'Esta é uma das top-10 senhas mais comuns'
        else if match.rank <= 100
          'Esta é uma das top-100 senhas mais comuns'
        else
          'Esta é uma senha muito comum'
      else if match.guesses_log10 <= 4
        'Isso é semelhante a uma senha comumente usada'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Evite usar apenas uma palavra como senha.'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Nomes e sobrenomes sozinhos são fáceis de adivinhar'
      else
        'Nomes e sobrenomes são fáceis de adivinhar'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Primeira letra em maiúsculo não ajuda muito."
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Utilizar somente letras maiúsculas é quase tão fácil de adivinhar quanto somente minúsculas."

    if match.reversed and match.token.length >= 4
      suggestions.push "Palavras invertidas não são muito mais difíceis de adivinhar."
    if match.l33t
      suggestions.push "Fazer substituição como ‘@‘ em vez de ‘a’ não ajudam muito."

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
