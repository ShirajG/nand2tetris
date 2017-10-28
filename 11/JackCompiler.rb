require 'byebug'
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

  attr_reader :tokens, :analyzed_file

  def initialize(tokenizer)
    @tokens = tokenizer.tokens
    @filename = tokenizer.filename
    @token_idx = 0
    @xml = File.open(@filename + '.xml', 'w')
    # puts @tokens
    @analyzed_file = compile_class
    print_node @analyzed_file
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

  def advance(node)
    if current_token[:type] == 'identifier'
      node[:value] << parse_identifier
    else
      node[:value] << current_token
    end

    @token_idx += 1
  end

  def parse_identifier
    current_token[:declaration?] = false
    prev_token = @tokens[@token_idx - 1]
    prev_prev_token = @tokens[@token_idx -2]
    # Class if starts with a capital letter
    if current_token[:value][0].upcase == current_token[:value][0]
      current_token[:category] = "class"
      if prev_token[:value] == "class"
        current_token[:declaration?] = true
      end
    # subroutine if preceeded by a dot or 'void'
    elsif %w(. void).include? prev_token[:value]
      current_token[:category] = "subroutine"
      if prev_token[:value] == 'void'
        current_token[:declaration?] = true
      end
    # let is assignment to a var, not sure what scope
    elsif prev_token[:value] == 'let'
      current_token[:category] = "?????"
    # part of an expression
    elsif %w(+ - = / * | ~).include? prev_token[:value]
      current_token[:category] = "?????"
    # Must be a declaration if Class is specified
    elsif prev_token[:category] == "class"
      if %w(method function constructor).include? prev_prev_token[:value]
        current_token[:category] = "subroutine"
      else
        current_token[:category] = "var"
      end
      current_token[:declaration?] = true
    elsif %w(int char boolean).include? prev_token[:value]
      case prev_prev_token[:value]
      when 'static'
        current_token[:category] = "static"
      when 'field'
        current_token[:category] = "field"
      when '('
        current_token[:category] = "argument"
      else
        current_token[:category] = "var"
      end
      current_token[:declaration?] = true
    elsif prev_token[:value] == ','
      current_token[:category] = prev_prev_token[:category]
      current_token[:declaration?] = prev_prev_token[:declaration?]
    elsif prev_token[:value] == 'do'
      current_token[:category] = 'subroutine'
    elsif prev_token[:value] == '('
      current_token[:category] == '?????'
    else
      puts '========================'
      puts '<<<<<<<<<<<<<<<<<<<<<<<<'
      puts prev_prev_token
      puts prev_token
      puts '>>>>>>>>>>>>>>>>>>>>>>>>'
      puts current_token
    end
    puts current_token
    current_token
  end

  def compile_class
    # 'class' className '{' classVarDec* subroutineDec* '}'
    class_node = node
    class_node[:type] = 'class'

    3.times do
      advance class_node
    end

    while ["static", "field"].include? current_token[:value]
      class_node[:value] << compile_class_var_dec
    end

    while ["constructor", "function","method"].include? current_token[:value]
      class_node[:value] << compile_subroutine
    end

    class_node[:value] << current_token
    return class_node
  end

  def compile_class_var_dec
    # ('static' | 'field') type varName (',' varName)* ';'
    class_var_dec_node = node
    class_var_dec_node[:type] = 'classVarDec'

    3.times do
      advance class_var_dec_node
    end

    while current_token[:value] == ','
      2.times do
        advance class_var_dec_node
      end
    end

    advance class_var_dec_node
    return class_var_dec_node
  end

  def compile_subroutine
    # ('constructor'|'function'|'method') ('void'|type) subroutineName '(' parameterList ')' subroutineBody
    subroutine_node = node
    subroutine_node[:type] = 'subroutineDec'

    4.times do
      advance subroutine_node
    end

    subroutine_node[:value] << compile_parameter_list

    advance subroutine_node
    subroutine_node[:value] << compile_subroutine_body
    return subroutine_node
  end

  def compile_subroutine_body
    # '{' varDec* statements '}'
    subroutine_body_node = node
    subroutine_body_node[:type] = "subroutineBody"

    advance subroutine_body_node


    while current_token[:value] == 'var'
      subroutine_body_node[:value] << compile_var_dec
    end

    subroutine_body_node[:value] << compile_statements

    advance subroutine_body_node
    return subroutine_body_node
  end

  def compile_parameter_list
    # ((type varName)(',' type varName)*)?
    parameter_list_node = node
    parameter_list_node[:type] = 'parameterList'

    if %w(identifier keyword).include? current_token[:type]
      2.times do
        advance parameter_list_node
      end

      while current_token[:value] == ","
        3.times do
          advance parameter_list_node
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
      advance var_dec_node
    end

    while current_token[:value] == ','
      2.times do
        advance var_dec_node
      end
    end

    advance var_dec_node
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
      advance let_node
    end

    if current_token[:value] == '['
      advance let_node
      let_node[:value] << compile_expression
      advance let_node
    end

    advance let_node

    let_node[:value] << compile_expression
    advance let_node

    return let_node
  end

  def compile_if
    # 'if' '(' expression ')' '{' statements '}' ('else' '{' statements '}')?
    if_node = node
    if_node[:type] = 'ifStatement'

    2.times do
      advance if_node
    end

    if_node[:value] << compile_expression

    2.times do
      advance if_node
    end

    if_node[:value] << compile_statements
    advance if_node


    if current_token[:value] == 'else'
      2.times do
        advance if_node
      end

      if_node[:value] << compile_statements
      advance if_node

    end

    return if_node
  end

  def compile_while
    # 'while' '(' expression ')' '{' statements '}'
    while_node = node
    while_node[:type] = 'whileStatement'

    2.times do
      advance while_node
    end

    while_node[:value] << compile_expression

    2.times do
      advance while_node
    end

    while_node[:value] << compile_statements

    advance while_node
    return while_node
  end

  def compile_do
    # 'do' subroutineCall ';'
    do_node = node
    do_node[:type] = 'doStatement'
    advance do_node

    if next_token[:value] == '.'
      4.times do
        advance do_node
      end

      do_node[:value] << compile_expression_list
      advance do_node
    else
      2.times do
        advance do_node
      end

      do_node[:value] << compile_expression_list
      advance do_node
    end

    advance do_node


    return do_node
  end

  def compile_return
    # 'return' expression? ';'
    return_node = node
    return_node[:type] = 'returnStatement'

    advance return_node


    if(current_token[:value] != ';')
      return_node[:value] << compile_expression
    end

    advance return_node


    return return_node
  end

  def compile_expression
    # term (op term)*
    expression_node = node
    expression_node[:type] = 'expression'

    expression_node[:value] << compile_term

    while @@ops.include? current_token[:value]
      advance expression_node

      expression_node[:value] << compile_term
    end

    return expression_node
  end

  def compile_term
    # integerConstant | stringConstant | keywordConstant | '(' expression ')' | unaryOp term | varName | varName '[' expression  ']' | subroutineCall
    term_node = node
    term_node[:type] = 'term'
    if %w(integerConstant stringConstant keyword).include? current_token[:type]
      advance term_node

    elsif current_token[:value] == '('
      advance term_node

      term_node[:value] << compile_expression
      advance term_node

    elsif @@unaryOps.include? current_token[:value]
      advance term_node

      term_node[:value] << compile_term
    elsif current_token[:type] == "identifier"
      if ['.', '('].include? next_token[:value]
        if next_token[:value] == '.'
          4.times do
            advance term_node
          end

          term_node[:value] << compile_expression_list
          advance term_node

        else
          2.times do
            advance term_node
          end

          term_node[:value] << compile_expression_list
          advance term_node
        end
      elsif next_token[:value] == '['
        2.times do
          advance term_node

        end
        term_node[:value] << compile_expression
        advance term_node

      else
        advance term_node
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
        advance expression_list_node

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
  def initialize(*args)
    @class_table = {}
    @subroutine_table = {}
  end

  def start_subroutine
  end

  def define
  end

  def var_count
  end

  def kind_of
  end

  def type_of
  end

  def index_of
  end
end

class VMWriter
  def initialize(args)
    @outfile = nil
  end

  def write_push(*args)

  end

  def write_pop(*args)

  end

  def write_arithmetic(*args)

  end

  def write_label(*args)

  end

  def write_goto(*args)

  end

  def write_if(*args)

  end

  def write_call(*args)

  end

  def write_function(*args)

  end

  def write_return(*args)

  end

  def close
    @outfile.close
  end
end

class JackCompiler
  def initialize
    if File.file?(ARGV[0])
      CompilationEngine.new(JackTokenizer.new(ARGV[0])).analyzed_file
    end

    if File.directory?(ARGV[0])
      files = Dir[ARGV[0] + "/*.jack"]
      files.each do |file|
        CompilationEngine.new(JackTokenizer.new(file)).analyzed_file
      end
    end
  end
end

JackCompiler.new()
