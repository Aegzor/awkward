# -*- coding: utf-8 -*-
require './rdparse'
require './syntax_tree'

class Awkward

  def initialize

    @awkward = Parser.new("Awkward:>") do

################################################################################
#     Tokens
################################################################################

      token(/#.*/)

      # string
      token(/"[^"\\]*"/) { |t| t }

      # digits
      token(/\d+/) { |t| t.to_i }

      # identifier
      token(/[a-zA-Z][a-zA-Z0-9_]*/) { |t| t }

      # single non-word characters
      token(/[^\w\s]/) { |t| t }

      # ignore comments and whitespace
      token(/[\t\ ]+/)
      token(/\n/)

################################################################################
#     Statements
################################################################################

      start :program do
        match(:stmt_list) { |list| Program.new(list) }
      end

      rule :stmt_list do
        match(:stmt_list, :stmt) do |list, stmt|
          ( list + [stmt])
        end
        match(:stmt) { |stmt| [stmt]}
      end

      rule :enclosed_stmt_list do
        match(:enclosed_stmt, :enclosed_stmt_list) do |stmt, stmt_list|
          [stmt] + stmt_list
        end
        match(:enclosed_stmt) { |stmt| [stmt] }
      end

      rule :stmt do
        match(:compound_stmt)
        match(:function_def)
        match(:function_call, ";")
        match(:initialize_const_var, ";")
        match(:initialize_var, ";")
        match(:assignment_stmt, ";")
        match(:declare_var, ";")
      end

      rule :enclosed_stmt do
        match(:compound_stmt)
        match(:return_stmt, ";")
        match(:break_stmt, ";")
        match(:initialize_var, ";")
        match(:declare_var, ";")
        match(:assignment_stmt, ";")
        match(:function_call, ";")
      end

################################################################################
#     Variables
################################################################################

      rule :initialize_var do
        match(:seq_data_type, :identifier, "=", :reference) do
          |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("list", :identifier, "=", :list) do |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("dict", :identifier, "=", :dict) do |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("int", :identifier, "=", :a_expr) do |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("float", :identifier, "=", :a_expr) do |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("string", :identifier, "=", :concat_expr) do
          |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
        match("bool", :identifier, "=", :bool) do |data_type, name, _, value|
          InitializeVar.new(data_type, name, BoolLiteral.new(value) )
        end
        match("bool", :identifier, "=", :reference) do
          |data_type, name, _, value|
          InitializeVar.new(data_type, name, value)
        end
      end

      rule :initialize_const_var do
        match("constant", :initialize_var)
      end

      rule :declare_var do
        match(:seq_data_type, :identifier){ |data_type, name|   DeclareVar.new(data_type, name) }
        match(:basic_data_type, :identifier) { |data_type, name|   DeclareVar.new(data_type, name) }
      end

      rule :assignment_stmt do
        match(:identifier, :assignment_operator, :expr) do |lh, op, rh|
          AssignVariable.new(lh, op, rh)
        end
        match(:subscription, :assignment_operator, :expr) do |lh, op, rh|
          name = lh[:name]
          index = lh[:index]
          AssignVariable.new(name, op, rh, index)
        end
      end

################################################################################
#     Functions
################################################################################

      rule :function_call do

        match("print", "(", :expr, ")") do |_, _, value, _|
          PrintFunction.new(value)
        end

        match("printline", "(", :expr, ")") do |_, _, value, _|
          PrintlineFunction.new(value)
        end

        # TODO: fix :>
        match("read", "(", ")") do |_, _, _|
          ReadFunction.new()
        end

        match("pop", "(", :primary, ")") do |_, _, source, _|
          PopFunction.new(source)
        end

        match("append", "(", :primary, ",", :expr, ")") do |_, _, source, _, value, _|
          AppendFunction.new(source, value)
        end

        match("append", "(", :primary, ",", :list, ")") do |_, _, source, _, value, _|
          AppendFunction.new(source, value);
        end

        match("remove", "(", :primary, ",", :a_expr, ")") do |_, _, source, _, index, _|
          RemoveFunction.new(source, index)
        end

        match("concatenate", "(", :primary, ",", :primary, ")") do |_, _, source, _, value, _|
          ConcatFunction.new(source, value)
        end

        match("length", "(", :primary, ")") do |_, _, source, _|
          LengthFunction.new(source)
        end

        match("string", "(", :expr, ")") do |_, _, source, _|
          StringFunction.new(source)
        end

        match("int", "(", :expr, ")") do |_, _, source, _|
          IntFunction.new(source)
        end

        match("float", "(", :expr, ")") do |_, _, source, _|
          FloatFunction.new(source)
        end

        match(:identifier, "(", ")")  { |name, _, _| FunctionCall.new(name)}
        match(:identifier, "(", :argument_list, ")") do
          |name, _, list, _|
          FunctionCall.new(name, list)
        end
      end

      rule :function_def do

        match(:data_type, "function", :identifier, "(",
              ")", :enclosed_stmt_list, "end") do
          |data_type, _, name, _, _, stmts, _|
          FunctionDefinition.new(data_type, name, stmts, [])
        end

        match(:data_type, "function", :identifier, "(", :parameter_list,
              ")", :enclosed_stmt_list, "end") do
          |data_type, _, name, _, parameters, _, stmts, _|
          FunctionDefinition.new(data_type, name, stmts, parameters)
        end

        match("void", "function", :identifier, "(",
              ")", :enclosed_stmt_list, "end") do
          |data_type, _, name, _, _, stmts, _|
          FunctionDefinition.new(data_type, name, stmts, [])
        end

        match("void", "function", :identifier, "(",:parameter_list,
              ")", :enclosed_stmt_list, "end") do
          |data_type, _, name, _, parameters, _, stmts, _|
          FunctionDefinition.new(data_type, name, stmts, parameters)
        end

      end

      rule :argument_list do
        match(:argument_list, ",", :expr) do |list, _, value|
          (list + [value]).flatten
        end
        match(:expr) { |value| [value] }
      end

      rule :parameter_list do
        match(:parameter_list, ",", :data_type, :identifier) do
          |list, _,data_type, name|
          list + [[data_type, name]]
        end
        match(:data_type, :identifier) do |data_type, name|
          [[data_type, name]]
        end
      end

################################################################################
#     Compound Statements
################################################################################

      rule :compound_stmt do
        match(:if_stmt)
        match(:while_stmt)
        match(:for_stmt)
      end

      rule :for_stmt do
        match("for", "(", :identifier, "in", :concat_expr,
              ")", :enclosed_stmt_list, "end") do
          |_, _, id, _, source, _, stmts, _|
          ForConstruct.new(id, source, stmts)
        end
        match("for", "(", :identifier, "in", :integer, ":",
              :integer, ")", :enclosed_stmt_list, "end") do
          |_, _, id, _, first, _, second, _, stmts, _ |

          source = [first, second]

          ForConstruct.new(id, source, stmts)
        end
      end

      rule :while_stmt do
        match("while", "(", :and_or_test, ")", :enclosed_stmt_list, "end") do
          |_, _, condition, _, stmts, _|
          WhileConstruct.new(condition, stmts)
        end
      end

      rule :if_stmt do
        match(:if_part, :else_part, "end") do |if_part, else_part, _|
          if_objects = ([if_part] + [else_part]).flatten
          IfConstruct.new(if_objects)
        end
        match(:if_part, :elsif_part, :else_part, "end") do
          |if_part, elsif_part, else_part, _|
          if_objects = ([if_part] + [elsif_part] + [else_part]).flatten
          IfConstruct.new(if_objects)
        end
        match(:if_part, :elsif_part, "end") do |if_part, elsif_part, _|
          if_objects = ([if_part] + [elsif_part]).flatten
          IfConstruct.new(if_objects)
        end
        match(:if_part, "end") { |if_part, _| IfConstruct.new(if_part) }
      end

      rule :if_part do
        match("if", "(", :and_or_test, ")", :enclosed_stmt_list) do
          |_, _, condition, _, stmts|
          [IfObject.new(stmts, condition)]
        end
      end

      rule :elsif_part do
        match(:elsif_part, "elsif", "(", :and_or_test, ")",
              :enclosed_stmt_list) do |list, _, _, condition, _, stmts|
          list + [IfObject.new(stmts, condition)]
        end

        match("elsif", "(", :and_or_test, ")", :enclosed_stmt_list) do
          |_, _, condition, _, stmts|
          [IfObject.new(stmts, condition)]
        end
      end

      rule :else_part do
        match("else", :enclosed_stmt_list) do |_, stmts|
          [IfObject.new(stmts)]
        end
      end

################################################################################
#     Return/ Break
################################################################################

      rule :break_stmt do
        match("break") { |_| Break.new() }
      end

      rule :return_stmt do
        match("return", "(", :expr, ")") { |_, _, value, _| Return.new(value) }
        match("return", :expr) { |_, value| Return.new(value) }
        match("return") { |_| Return.new() }
      end

################################################################################
#     Operators
################################################################################

      rule :assignment_operator do
        match("+", "=") { |_, _| "+=" }
        match("-", "=") { |_, _| "-=" }
        match("*", "=") { |_, _| "*=" }
        match("/", "=") { |_, _| "/=" }
        match("%", "=") { |_, _| "%=" }
        match("=")	{ |_, _| "=" }
      end

      rule :comp_operator do
        match("=", "=") { |_, _| "==" }
        match(">", "=") { |_, _| ">=" }
        match("<", "=") { |_, _| "<=" }
        match("!", "=") { |_, _| "!=" }
        match(">")	{ |_| ">" }
        match("<")	{ |_| "<" }
      end

################################################################################
#     Expressions
################################################################################

      rule :expr do
        match("(", :expr, ")")
        match(:concat_expr)
        match(:a_expr)
      end

      rule :a_expr do
        match(:a_expr, "+", :m_expr) do |lh, op, rh|
          ArithmeticExpr.new(lh, op, rh)
        end
        match(:a_expr, "-", :m_expr) do |lh, op, rh|
          ArithmeticExpr.new(lh, op, rh)
        end
        match(:m_expr)
      end

      rule :m_expr do
        match(:m_expr, "*", :arithmetic_primary) do |lh, op, rh|
          ArithmeticExpr.new(lh, op, rh)
        end
        match(:m_expr, "/", :arithmetic_primary) do |lh, op, rh|
          ArithmeticExpr.new(lh, op, rh)
        end
        match(:m_expr, "%", :arithmetic_primary) do |lh, op, rh|
          ArithmeticExpr.new(lh, op, rh)
        end
        match(:arithmetic_primary)
      end

      rule :concat_expr do
        match(:concat_expr, ",", :concat_primary) { |lh, _, rh| ConcatExpr.new(lh, rh) }
        match(:concat_primary)
        match("(", :concat_expr, ")")
      end

################################################################################
#     Comparison
################################################################################

      rule :and_or_test do
        match(:and_or_test, "and", :not_test) do |lh, op, rh| 
          AndOrTest.new(lh, op, rh)
        end
        match(:and_or_test, "or", :not_test) do |lh, op, rh|
          AndOrTest.new(lh, op, rh)
        end
        match(:not_test)
      end

      rule :not_test do
        match("not", :comparison) do |op, comparison|
          NotTest.new(comparison, op)
        end
        match(:comparison) # { |comparison| NotTest.new(comparison) }
        match("(", :and_or_test, ")")
      end

      rule :comparison do
        match(:expr, :comp_operator, :expr) do |lh, op, rh|
          Comparison.new(lh, op, rh)
        end
      end

################################################################################
#     Data Types
################################################################################

      rule :data_type do
        match(:seq_data_type)
        match(:basic_data_type)
      end

      rule :seq_data_type do
        match("list") { |data_type| data_type}#DataType.new(data_type) }
        match("dict") { |data_type| data_type}#DataType.new(data_type) }
      end

      rule :basic_data_type do
        match("int") { |data_type| data_type}#DataType.new(data_type) }
        match("float") { |data_type| data_type}#DataType.new(data_type) }
        match("string") { |data_type| data_type}#DataType.new(data_type) }
        match("bool") { |data_type| data_type}#DataType.new(data_type) }
      end

################################################################################
#     Literals
################################################################################

      rule :literal do
        match(:list)
        match(:dict)
        match(:string)
        match(:floatnumber)
        match(:integer)
        match(:bool)
      end

      rule :list do
        match("[", :list_content, "]") do |_, content, _|
          ListLiteral.new(content)
        end
        match("[", "]") do |_, _|
          ListLiteral.new()
        end
      end

      rule :list_content do
        match(:list_content, ",", :primary) do |content, _, literal|
          content + [literal.eval]
        end
        match(:primary) { |literal| [literal.eval] }
      end

      rule :dict do
        match("{", :dict_content, "}")
      end

      rule :dict_content do
        match(:dict_content, ",", :literal, ":", :literal)
        match(:literal, ":", :literal)
      end

      rule :string do
        match(/"([^"\\]*)"/) do |value|
          # strip the quotation marks
          value = value[1, value.length-2]
          StringLiteral.new(value.to_s)
        end
      end

      rule :integer do
        match(:digits) { |value| IntLiteral.new(value)}
        match("-", :digits) { |_, value| IntLiteral.new(-value) }
      end

      rule :floatnumber do
        match(:digits, ".", :digits) do |lh, _, rh|
          FloatLiteral.new("#{lh}.#{rh}".to_f)
        end
        match("-", :digits, ".", :digits) do |_, lh, _, rh|
          FloatLiteral.new("-#{lh}.#{rh}".to_f)
        end
        match(".", :digits) do | _, rh|
          FloatLiteral.new("0.#{rh}".to_f)
        end
        match("-", ".", :digits) do |_, _, rh|
          FloatLiteral.new("-0.#{rh}".to_f)
        end
      end

      rule :bool do
        match("true") { |_| true}
        match("false") { |_| false}
      end

      rule :digits do
        match(Integer)
      end

################################################################################
#     Miscellaneous
################################################################################

      rule :primary do
        match(:literal)
        match(:reference)
      end

      rule :concat_primary do
        match(:string)
        match(:reference)
      end

      rule :arithmetic_primary do
        match("(", :a_expr, ")") { |_, expr, _| expr }
        match(:reference)
        match(:floatnumber)
        match(:integer)
      end
      
      rule :identifier do
        match(/[a-zA-Z][a-zA-Z0-9_]*/) { |name| Identifier.new(name) }
      end

      rule :reference do
        match(:function_call)# { |value| FunctionCall.new(value) }
        match(:subscription) do |subscript|
          name = subscript[:name]
          index = subscript[:index]
          RetreiveIdentifier.new(name, index)
        end
        match(:identifier) { |name| RetreiveIdentifier.new(name) }
      end

      rule :subscription do
        match(:identifier, "[", :expr, "]") do |name, _, index, _|
          {:name => name, :index => index}
        end
      end

    end



    def done(str)
      ["quit","exit","bye"].include?(str.chomp)
    end

    def parse
      print "awkward:> "
      str = gets
      if done(str) then
        puts "Bye."
      elsif done(str) == ""
        
      else
        puts "=> #{@awkward.parse str}"
        parse
      end
    end

    def parse_file(file_name)
      str = File.read(file_name)
      @awkward.parse str
    end

    def log(state = true)
      if state
        @awkward.logger.level = Logger::DEBUG
      else
        @awkward.logger.level = Logger::WARN
      end
    end

  end

end
