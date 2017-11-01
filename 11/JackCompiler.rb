# require 'byebug'
class SymbolTable
  attr_reader :current_table, :class_table

  def initialize
    @class_table = {}
    @subroutine_table = {}
    @current_table = @class_table
    @static_index = 0
    @field_index = 0
    @argument_index = 0
    @local_index = 0
  end

  def start_subroutine
    @subroutine_table = {}
    @argument_index = 0
    @local_index = 0
    @current_table = @subroutine_table
  end

  def define(variable)
    case variable[:kind]
    when 'field'
      @class_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @field_index
      }
      @field_index += 1
    when 'static'
      @class_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @static_index
      }
      @static_index += 1
    when 'argument'
      @subroutine_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @argument_index
      }
      @argument_index += 1
    when 'local'
      @subroutine_table[variable[:name]] = {
        kind: variable[:kind],
        type: variable[:type],
        num: @local_index
      }
      @local_index += 1
    end
  end

  def var_count(token)
  end

  def kind_of(token)
    lookup(token)[:kind]
  end

  def type_of(token)
    lookup(token)[:type]
  end

  def index_of(token)
    lookup(token)[:num]
  end

  def lookup token
    @current_table[token[:value]] || @class_table[token[:value]]
  end
end

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
    @symbol_table = SymbolTable.new()
    @code_writer = VMWriter.new(File.open(@filename + '.vm', 'w'))
    # @xml = File.open(@filename + '.xml', 'w')
    @analyzed_file = compile_class
    # puts  @tokens
    # puts @tokens
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
      lookup = lookup(current_token)
      if lookup
        current_token[:type] = lookup[:type]
        current_token[:kind] = lookup[:kind]
        current_token[:index] = lookup[:num]
      elsif current_token[:value][0].upcase == current_token[:value][0]
        current_token[:type] = 'class'
      else
        current_token[:type] = 'subroutine'
      end
    end
    node[:value] << current_token
    @token_idx += 1
  end

  def lookup(token)
    @symbol_table.lookup(token)
  end

  def compile_class
    # 'class' className '{' classVarDec* subroutineDec* '}'
    class_node = node
    class_node[:type] = 'class'

    advance class_node
    @code_writer.set_class(current_token)
    advance class_node
    advance class_node

    while ["static", "field"].include? current_token[:value]
      class_node[:value] << compile_class_var_dec
    end

    # puts @symbol_table.class_table


    while ["constructor", "function","method"].include? current_token[:value]
      class_node[:value] << compile_subroutine
      # puts @symbol_table.current_table
    end

    class_node[:value] << current_token
    @code_writer.close
    return class_node
  end

  def compile_class_var_dec
    # ('static' | 'field') type varName (',' varName)* ';'
    class_var_dec_node = node
    class_var_dec_node[:type] = 'classVarDec'

    class_var = {}

    class_var[:kind] = current_token[:value]
    advance class_var_dec_node

    class_var[:type] = current_token[:value]
    advance class_var_dec_node

    class_var[:name] = current_token[:value]
    @symbol_table.define(class_var)
    current_token[:type] = class_var[:type]
    current_token[:kind] = class_var[:kind]
    current_token[:declaration?] = true
    current_token[:index] = @symbol_table.index_of(current_token)
    advance class_var_dec_node

    while current_token[:value] == ','
      advance class_var_dec_node
      class_var[:name] = current_token[:value]
      @symbol_table.define(class_var)
      current_token[:type] = class_var[:type]
      current_token[:kind] = class_var[:kind]
      current_token[:declaration?] = true
      current_token[:index] = @symbol_table.index_of(current_token)
      advance class_var_dec_node
    end

    advance class_var_dec_node
    return class_var_dec_node
  end

  def compile_subroutine
    # ('constructor'|'function'|'method') ('void'|type) subroutineName '(' parameterList ')' subroutineBody
    subroutine_node = node
    subroutine_node[:type] = 'subroutineDec'

    @symbol_table.start_subroutine

    advance subroutine_node
    advance subroutine_node
    subroutine_name = current_token[:value]
    advance subroutine_node
    advance subroutine_node

    subroutine_node[:value] << compile_parameter_list
    locals_count = subroutine_node[:value].last[:value].length
    @code_writer.write_function(subroutine_name, locals_count)

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
      argument = {}
      argument[:kind] = 'argument'
      argument[:type] = current_token[:value]
      advance parameter_list_node
      argument[:name] = current_token[:value]
      current_token[:kind] = 'argument'
      current_token[:type] = argument[:type]
      current_token[:declaration?] = true
      @symbol_table.define(argument)
      current_token[:index] = @symbol_table.index_of(current_token)

      advance parameter_list_node


      while current_token[:value] == ","
        advance parameter_list_node
        argument[:type] = current_token[:value]
        advance parameter_list_node
        argument[:name] = current_token[:value]
        @symbol_table.define(argument)
        advance parameter_list_node
      end
    end
    return parameter_list_node
  end

  def compile_var_dec
    # 'var' type varName (',' varName)* ';'
    var_dec_node = node
    var_dec_node[:type] = 'varDec'

    variable = {}

    variable[:kind] = 'local'
    advance var_dec_node
    variable[:type] = current_token[:value]
    advance var_dec_node
    variable[:name] = current_token[:value]
    current_token[:declaration?] = true
    @symbol_table.define(variable)
    advance var_dec_node

    while current_token[:value] == ','
      advance var_dec_node
      variable[:name] = current_token[:value]
      current_token[:declaration?] = true
      @symbol_table.define(variable)
      advance var_dec_node
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
    #(className | varName) '.' subroutineName '(' expressionList ')'
      name = current_token[:value]
      advance do_node
      name += current_token[:value]
      advance do_node
      name += current_token[:value]
      advance do_node
      advance do_node

      do_node[:value] << compile_expression_list
      exp_count = 0
      do_node[:value].last[:value].each do |exp|
        if exp[:type] == 'expression'
          exp_count += 1
        end
      end

      @code_writer.write_call(name, exp_count)
      advance do_node
    else
    # subroutineName '(' expressionList ')'
      name = current_token[:value]
      advance do_node
      advance do_node

      do_node[:value] << compile_expression_list

      exp_count = 0
      do_node[:value].last[:value].each do |exp|
        if exp[:type] == 'expression'
          exp_count += 1
        end
      end

      @code_writer.write_call(name, exp_count)
      advance do_node
    end

    advance do_node
    # Do statement, pop return val to garbage
    @code_writer.write_pop('temp', 0)

    return do_node
  end

  def compile_return
    # 'return' expression? ';'
    return_node = node
    return_node[:type] = 'returnStatement'

    advance return_node

    if(current_token[:value] != ';')
      return_node[:value] << compile_expression
    else
      @code_writer.write_push('constant', 0)
    end

    advance return_node
    @code_writer.write_return
    return return_node
  end

  def compile_expression
    # term (op term)*
    expression_node = node
    expression_node[:type] = 'expression'

    expression_node[:value] << compile_term

    while @@ops.include? current_token[:value]
      operation = current_token[:value]

      advance expression_node
      expression_node[:value] << compile_term

      case operation
      when '+'
        @code_writer.write_arithmetic('add')
      when '*'
        @code_writer.write_call('Math.multiply', 2)
      end
    end

    return expression_node
  end

  def compile_term
    # integerConstant | stringConstant | keywordConstant | '(' expression ')' | unaryOp term | varName | varName '[' expression  ']' | subroutineCall
    term_node = node
    term_node[:type] = 'term'
    if current_token[:type] == 'integerConstant'
      @code_writer.write_push('constant', current_token[:value])
      advance term_node
    elsif current_token[:type] == 'stringConstant'
      advance term_node
    elsif current_token[:type] == 'keyword'
      advance term_node
    elsif current_token[:value] == '('
      advance term_node
      term_node[:value] << compile_expression
      advance term_node
    elsif @@unaryOps.include? current_token[:value]
      advance term_node
      term_node[:value] << compile_term
    elsif ['.', '('].include? next_token[:value]
    # Handle subroutine calls
      if next_token[:value] == '.'
      #(className | varName) '.' subroutineName '(' expressionList ')'
        name = current_token[:value]
        advance term_node
        name += current_token[:value]
        advance term_node
        name += current_token[:value]
        advance term_node
        advance term_node

        term_node[:value] << compile_expression_list
        exp_count = 0
        term_node[:value].last[:value].each do |exp|
          if exp[:type] == 'expression'
            exp_count += 1
          end
        end

        @code_writer.write_call(name, exp_count)
        advance term_node
      else
      # subroutineName '(' expressionList ')'
        name = current_token[:value]
        advance term_node
        advance term_node
        term_node[:value] << compile_expression_list
        exp_count = 0
        term_node[:value].last[:value].each do |exp|
          if exp[:type] == 'expression'
            exp_count += 1
          end
        end
        @code_writer.write_call(name, exp_count)
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
    puts "#{root_indent}<#{node[:type]}>"

    node[:value].each do |val|
      if val[:value].is_a? String
        @xml << "#{child_indent}<#{val[:type]}> #{val[:value]} </#{val[:type]}>\n"
        puts "#{child_indent}<#{val[:type]} #{val[:kind]} #{val[:index]} #{val[:declaration?] ? 'declaration' : '';}> #{val[:value]} </#{val[:type]}>"
      else
        print_node(val, nesting + 2)
      end
    end

    @xml <<  "#{root_indent}</#{node[:type]}>\n"
    puts "#{root_indent}</#{node[:type]}>"
  end
end

class VMWriter
  def initialize(file)
    @outfile = file
    @classname
  end

  def write_push(segment, index)
    @outfile << "push #{segment} #{index}\n"
  end

  def write_pop(segment, index)
    @outfile << "pop #{segment} #{index}\n"
  end

  def write_arithmetic(command)
    @outfile << "#{command}\n"
  end

  def write_label(label)

  end

  def write_goto(label)

  end

  def write_if(label)

  end

  def write_call(name, arg_count)
    @outfile << "call #{name} #{arg_count}\n"
  end

  def write_function(name, locals_count)
    @outfile << "function #{@class}.#{name} #{locals_count}\n"
  end

  def write_return
    @outfile << "return\n"
  end

  def set_class(token)
    @class = token[:value]
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
