class JackTokenizer
  @@symbols = %w({ } ( ) [ ] . , ; + - * / & | < > = ~)
  @@token_types = {
    keyword: "keyword", symbol: "symbol", identifier: "identifier",
    int: "integerConstant", str: "stringConstant" }

  @@keywords = {
    class: "class", method: "method", function: "function",
    constructor: "constructor", int: "int", boolean: "boolean",
    char: "char", void: "void", var: "var",
    static: "static", field: "field", let: "let",
    do: "do", if: "if", else: "else", while: "while",
    return: "return", true: "true", false: "false", null: "null",
    this: "this" }

  attr_reader :tokens, :filename

  def initialize(file)
    @tokens = []
    @xml = ""
    @filename = file.gsub('.jack','')
    @file = File.read(file)
      .gsub(/\/\/.+$/,"") # remove // comments
      .strip
    # puts @file

    within_quote = false
    within_comment = false
    current_string = ""
    file_length = @file.length
    @file.each_char.with_index do |char, i|
      # Keep track of when we are in a multi line comment. Ignore text.
      if char == '/' && @file[i+1] == '*'
        within_comment = true
      end

      if within_quote
        current_string += char;
      elsif within_comment
        # End comment when we hit '*/'
        if char == '/' && @file[i - 1] == '*'
          within_comment = false
        end
        next
      else
        if ["\r", "\n", " "].include? char
          current_string.strip!
          tokenize!(current_string) unless current_string == ""
          current_string = ""
        else
          current_string += char
          if file_length == i + 1
            tokenize! current_string
          end
        end
      end

      if char == '"'
        within_quote = !within_quote
      end
    end
    output_xml
  end

  def output_xml
    @xml << "<tokens>\n"
    @tokens.each do |token|
        token[:value].gsub!('"', '')
        @xml << "<#{token[:type]}> #{token[:value]} </#{token[:type]}>\n"
    end
    @xml << "</tokens>"

    File.open(@filename + '_T.xml', 'w') do |outfile|
      outfile << @xml
    end
  end

  def tokenize!(token_str)
    token = nil;
    if @@symbols.include?(token_str)
      token = {
        type: @@token_types[:symbol],
        value: token_str
      }
    elsif %w(class constructor function method field static var int char boolean void true false null this let do if else while return).include?(token_str)
      token = {
        type: @@token_types[:keyword],
        value: token_str
      }
    elsif /^\".+\"$/.match token_str
      token = {
        type: @@token_types[:str],
        value: token_str
      }
    else
      if contains_symbols(token_str)
        if (%w(, ;).include? token_str[-1])
          tokenize!(token_str[0..-2])
          tokenize!(token_str[-1])
        elsif token_str[0] == '.'
          tokenize!(token_str[0])
          tokenize!(token_str[1..-1])
        else
          if(/\..+\(.*\)$/.match(token_str))
            dot_position = token_str.index('.')
            token1 = token_str[0...dot_position]
            rest = token_str[dot_position..-1]
            tokenize!(token1)
            tokenize!(rest)
          elsif(/\(\)$/.match(token_str))
            tokenize!(token_str[0..-3])
            tokenize!(token_str[-2])
            tokenize!(token_str[-1])
          elsif(/^\(.*\)$/.match(token_str))
            tokenize!(token_str[0])
            tokenize!(token_str[1..-2])
            tokenize!(token_str[-1])
          elsif(/\[.*\]$/.match(token_str))
            left_bracket_position = token_str.index('[')
            tokenize!(token_str[0...left_bracket_position])
            tokenize!(token_str[(left_bracket_position)...-1])
            tokenize!(token_str[-1])
          elsif(@@symbols.include?(token_str[0]))
            tokenize!(token_str[0])
            tokenize!(token_str[1..-1])
          elsif(@@symbols.include?(token_str[-1]))
            tokenize!(token_str[0...-1])
            tokenize!(token_str[-1])
          elsif(token_str.index('.'))
            dot_position = token_str.index('.')
            tokenize! token_str[0...dot_position]
            tokenize! token_str[dot_position..-1]
          elsif(token_str.index('('))
            paren_position = token_str.index('(')
            tokenize! token_str[0...paren_position]
            tokenize! token_str[paren_position]
            tokenize! token_str[paren_position+1..-1]
          else
             puts "UNHANDLED!: #{token_str} "
          end
        end
      else
        if is_number?(token_str)
          token = {
            type: @@token_types[:int],
            value: token_str
          }
        else
          token = {
            type: @@token_types[:identifier],
            value: token_str
          }
        end
      end
    end

    @tokens << token unless token.nil?
  end

  def contains_symbols(token_str)
    !(token_str.split('') & @@symbols).empty?
  end

  def is_number?(obj)
    obj.to_f.to_s == obj.to_s || obj.to_i.to_s == obj.to_s
  end
end

class CompilationEngine
  @@ops = %w(+ - * / & | < > =)
  @@unaryOps = %w(- ~)
  @@keywordConstants = %w(true false null this)

  attr_reader :tokens

  def initialize(tokenizer)
    @tokens = tokenizer.tokens
    @filename = tokenizer.filename
    @parse_tree = ""
    @token_idx = 0
    @xml = File.open(@filename + '.xml', 'w')
    # puts @tokens
    compile_class
  end

  def node
    { type: nil, value:[] }
  end

  def current_token
    @tokens[@token_idx]
  end

  def next_token
    @tokens[@token_idx + 1]
  end

  def advance
    @token_idx += 1
  end

  def compile_class
    # 'class' className '{' classVarDec* subroutineDec* '}'
    class_node = node
    class_node[:type] = 'class'

    3.times do
      class_node[:value] << current_token
      advance
    end

    while ["static", "field"].include? current_token[:value]
      class_node[:value] << compile_class_var_dec
    end

    while ["constructor", "function","method"].include? current_token[:value]
      class_node[:value] << compile_subroutine
    end

    class_node[:value] << current_token
    advance
  end

  def compile_class_var_dec
    # ('static' | 'field') type varName (',' varName)* ';'
    class_var_dec_node = node
    class_var_dec_node[:type] = 'classVarDec'

    3.times do
      class_var_dec_node[:value] << current_token
      advance
    end

    while current_token[:value] == ','
      2.times do
        class_var_dec_node[:value] << current_token
        advance
      end
    end

    class_var_dec_node[:value] << current_token
    advance
    return class_var_dec_node
  end

  def compile_subroutine
    # ('constructor'|'function'|'method') ('void'|type) subroutineName '(' parameterList ')' subroutineBody
    subroutine_node = node
    subroutine_node[:type] = 'subroutineDec'

    4.times do
      subroutine_node[:value] << current_token
      advance
    end

    subroutine_node[:value] << compile_parameter_list

    subroutine_node[:value] << current_token
    advance

    subroutine_node[:value] << compile_subroutine_body

    return subroutine_node
  end

  def compile_subroutine_body
    # '{' varDec* statements '}'
    subroutine_body_node = node
    subroutine_body_node[:type] = "subroutineBody"

    subroutine_body_node[:value] << current_token
    advance

    while current_token[:value] == 'var'
      subroutine_body_node[:value] << compile_var_dec
    end

    subroutine_body_node[:value] << compile_statements

    subroutine_body_node[:value] << current_token
    advance

    return subroutine_body_node
  end

  def compile_parameter_list
    # ((type varName)(',' type varName)*)?
    parameter_list_node = node
    parameter_list_node[:type] = 'parameterList'

    if %w(identifier keyword).include? current_token[:type]
      2.times do
        parameter_list_node[:value] << current_token
        advance
      end

      while current_token[:value] == ","
        3.times do
          parameter_list_node[:value] << current_token
          advance
        end
      end
    end
    return parameter_list_node
  end

  def compile_var_dec
    # 'var' type varName (',' varName)* ';'
    var_dec_node = node
    var_dec_node[:type] = 'varDec'
    3.times do
      var_dec_node[:value] << current_token
      advance
    end

    while current_token[:value] == ','
      2.times do
        var_dec_node[:value] << current_token
        advance
      end
    end

    var_dec_node[:value] << current_token
    advance

    return var_dec_node
  end

  def compile_statements
    # statement*
    statements_node = node
    statements_node[:type] = 'statements'
    while %w(while let if do return).include? current_token[:value]
      case current_token[:value]
      when 'while'
        statements_node[:value] << compile_while
      when 'let'
        statements_node[:value] << compile_let
      when 'if'
        statements_node[:value] << compile_if
      when 'do'
        statements_node[:value] << compile_do
      when 'return'
        statements_node[:value] << compile_return
      end
    end

    return statements_node
  end

  def compile_let
    # 'let' varName ('[' expression ']')? '=' expression ';'
    let_node = node
    let_node[:type] = 'letStatement'
    2.times do
      let_node[:value] << current_token
      advance
    end

    if current_token[:value] == '['
      let_node[:value] << current_token
      advance
      let_node[:value] << compile_expression
      let_node[:value] << current_token
      advance
    end

    let_node[:value] << current_token
    advance

    let_node[:value] << compile_expression
    let_node[:value] << current_token
    advance
    return let_node
  end

  def compile_if
    # 'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
    if_node = node
    if_node[:type] = 'ifStatement'

    2.times do
      if_node[:value] << current_token
      advance
    end

    if_node[:value] << compile_expression

    2.times do
      if_node[:value] << current_token
      advance
    end

    if_node[:value] << compile_statements

    if_node[:value] << current_token
    advance

    if current_token[:value] == 'else'
      2.times do
        if_node[:value] << current_token
        advance
      end

      if_node[:value] << compile_statements

      if_node[:value] << current_token
      advance
    end

    return if_node
  end

  def compile_while
    # 'while' '(' expression ')' '{' statements '}'
    while_node = node
    while_node[:type] = 'whileStatement'

    2.times do
      while_node[:value] << current_token
      advance
    end

    while_node[:value] << compile_expression

    2.times do
      while_node[:value] << current_token
      advance
    end

    while_node[:value] << compile_statements

    while_node[:value] << current_token
    advance

    return while_node
  end

  def compile_do
    # 'do' subroutineCall ';'
    do_node = node
    do_node[:type] = 'doStatement'

    do_node[:value] << current_token
    advance

    if next_token[:value] == '.'
      4.times do
        do_node[:value] << current_token
        advance
      end
      do_node[:value] << compile_expression_list
      do_node[:value] << current_token
      advance
    else
      2.times do
        do_node[:value] << current_token
        advance
      end
      do_node[:value] << compile_expression_list
      do_node[:value] << current_token
      advance
    end

    do_node[:value] << current_token
    advance

    return do_node
  end

  def compile_return
    # 'return' expression? ';'
    return_node = node
    return_node[:type] = 'returnStatement'

    return_node[:value] << current_token
    advance

    if(current_token[:value] != ';')
      return_node[:value] << compile_expression
    end

    return_node[:value] << current_token
    advance

    return return_node
  end

  def compile_expression
    # term (op term)*
    expression_node = node
    expression_node[:type] = 'expression'

    expression_node[:value] << compile_term

    while @@ops.include? current_token[:value]
      expression_node[:value] << current_token
      advance
      expression_node[:value] << compile_term
    end

    return expression_node
  end

  def compile_term
    # integerConstant | stringConstant | keywordConstant | '(' expression ')' | unaryOp term | varName | varName '[' expression  ']' | subroutineCall
    term_node = node
    term_node[:type] = 'term'
    if %w(integerConstant stringConstant keyword).include? current_token[:type]
      term_node[:value] << current_token
      advance
    elsif current_token[:value] == '('
      term_node[:value] << current_token
      advance
      term_node[:value] << compile_expression
      term_node[:value] << current_token
      advance
    elsif @@unaryOps.include? current_token[:value]
      term_node[:value] << current_token
      advance
      term_node[:value] << compile_term
    elsif current_token[:type] == "identifier"
      if ['.', '('].include? next_token[:value]
        if next_token[:value] == '.'
          4.times do
            term_node[:value] << current_token
            advance
          end
          term_node[:value] << compile_expression_list
          term_node[:value] << current_token
          advance
        else
          2.times do
            term_node[:value] << current_token
            advance
          end
          term_node[:value] << compile_expression_list
          term_node[:value] << current_token
          advance
        end
      elsif next_token[:value] == '['
        2.times do
          term_node[:value] << current_token
          advance
        end
        term_node[:value] << compile_expression
        term_node[:value] << current_token
        advance
      else
        term_node[:value] << current_token
        advance
      end
    end

    return term_node
  end

  def compile_expression_list
    # (expression (',' expression)*)?
    expression_list_node = node
    expression_list_node[:type] = 'expressionList'

    if is_term?(current_token)
      expression_list_node[:value] << compile_expression
      while current_token[:value] == ','
        expression_list_node[:value] << current_token
        advance
        expression_list_node[:value] << compile_expression
      end
    end

    return expression_list_node
  end

  def is_term?(token)
    (%w(identifier integerConstant stringConstant keyword).include? token[:type]) || (token[:value] == '(') || (@@unaryOps.include? token[:value])
  end

  def print_node(node, nesting=2)
    child_indent = ""
    root_indent = ""

    nesting.times do
      child_indent += ' '
    end

    (nesting - 2).times do
      root_indent += ' '
    end

    @xml << "#{root_indent}<#{node[:type]}>\n"
    # puts "#{root_indent}<#{node[:type]}>"

    node[:value].each do |val|
      if val[:value].is_a? String
        @xml << "#{child_indent}<#{val[:type]}> #{val[:value]} </#{val[:type]}>\n"
        # puts "#{child_indent}<#{val[:type]}> #{val[:value]} </#{val[:type]}>"
      else
        print_node(val, nesting + 2)
      end
    end

    @xml <<  "#{root_indent}</#{node[:type]}>\n"
    # puts "#{root_indent}</#{node[:type]}>"
  end
end

class SymbolTable
end

class VMWriter
end

class JackCompiler
  def initialize
    if File.file?(ARGV[0])
      puts 'here'
      puts CompilationEngine.new(JackTokenizer.new(ARGV[0])).tokens
    end

    if File.directory?(ARGV[0])
      puts 'fdsfasd'
      files = Dir[ARGV[0] + "/*.jack"]
      files.each do |file|
        puts CompilationEngine.new(JackTokenizer.new(file)).tokens
      end
    end
  end
end


JackCompiler.new()















