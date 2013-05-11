#!/usr/bin/env ruby
# -*- coding: utf-8 -*-

@@scope = [{}]
@@functions = {}

@@reserved_words = ["list",
                    "dict",
                    "int",
                    "float",
                    "string",
                    "bool",
                    "constant",
                    "print",
                    "printline",
                    "read",
                    "pop",
                    "append",
                    "remove",
                    "concatenate",
                    "length",
                    "function",
                    "end",
                    "void",
                    "for",
                    "in",
                    "while",
                    "if",
                    "elsif",
                    "else",
                    "break",
                    "return",
                    "and",
                    "or",
                    "not",
                    "true",
                    "false"]

class Variable
  attr_accessor :name, :value, :data_type
  def initialize
    @name = ""
    @value = nil
    @data_type = ""
  end
end

class Program

  def initialize( stmts )
    @stmts = stmts
    eval
  end

  def eval
    @stmts.each do |stmt|
      stmt_value = stmt.eval

      if (stmt.class == IfConstruct or
          stmt.class == WhileConstruct or
          stmt.class == ForConstruct)

        # statement has a return in it
        if ( not ( stmt_value == :uninterrupted_stmt or
                   stmt_value == :break) )
          puts "Error: return found outside function"
          Kernel.exit
        end
      end

    end
  end

end

class RetreiveIdentifier

  def initialize(name, index = nil)
    @name = name	# String
    @index = index	# Expr
  end

  def eval
    name = @name.eval
    scope = get_variable_scope(name)
    if @index == nil
      @@scope[scope][name].value
    else
      index = @index.eval
      @@scope[scope][name].value[index]
    end
  end

end

class AssignVariable

  def initialize(lh, op, rh, index = nil)
    @lh = lh		# identifier
    @op = op		# string
    @rh = rh		# expr
    @index = index	# expr (used for subscriptions)
  end

  def eval
    lh = @lh.eval
    rh = @rh.eval
    scope_index = get_variable_scope(lh)

    expected_data_type = @@scope[scope_index][lh].data_type

    if (not check_type( expected_data_type, rh) and
        not expected_data_type == "list" )
      puts "Error: wrong data type in assignment."
      Kernel.exit
    end

    case expected_data_type
    when "int" then rh = rh.to_i
    when "float" then return rh = rh.to_f
    end

    # assign a variable in @@scope
    if @index == nil
      case @op
      when '+=' then return (@@scope[scope_index][lh].value += rh)
      when '-=' then return (@@scope[scope_index][lh].value -= rh)
      when '*=' then return (@@scope[scope_index][lh].value *= rh)
      when '/=' then return (@@scope[scope_index][lh].value /= rh)
      when '%=' then return (@@scope[scope_index][lh].value %= rh)
      when '='  then return (@@scope[scope_index][lh].value = rh)
      end

    # assign an element of a list in @@scope
    else
      index = @index.eval
      case @op
      when '+=' then return (@@scope[scope_index][lh].value[index] += rh)
      when '-=' then return (@@scope[scope_index][lh].value[index] -= rh)
      when '*=' then return (@@scope[scope_index][lh].value[index] *= rh)
      when '/=' then return (@@scope[scope_index][lh].value[index] /= rh)
      when '%=' then return (@@scope[scope_index][lh].value[index] %= rh)
      when '='  then return (@@scope[scope_index][lh].value[index] = rh)
      end
    end


  end

end

class DeclareVar

  def initialize(data_type, var_name)
    @data_type = data_type	# string
    @var_name = var_name	# identifier
  end

  def eval

    var_name = @var_name.eval

    if (@@reserved_words.include?(var_name))
      puts "Error: variable name is reserved."
      Kernel.exit
    end

    new_var = Variable.new

    new_var.name  = var_name
    new_var.data_type  = @data_type
    new_var.value = nil

    @@scope[0][var_name] = new_var

  end

end

class InitializeVar

  def initialize(data_type, var_name, value)
    @data_type = data_type	# string
    @var_name = var_name	# identifier
    @value = value		# list/ dict/ a_expr/ concat_expr/ bool/ reference
  end

  def eval

    var_name = @var_name.eval

    new_var = Variable.new

    new_var.data_type = @data_type
    new_var.name = var_name

    value = @value.eval

    if (@@reserved_words.include?(var_name))
      puts "Error: variable name is reserved."
      Kernel.exit
    end

    case @data_type
    when "int" then new_var.value = value.to_i
    when "float" then new_var.value = value.to_f
    when "bool" then new_var.value = value
    when "string" then new_var.value = value
    when "list" then new_var.value = value
    when "dict" then new_var.value = value
    end

    @@scope[0][new_var.name] = new_var
  end

end

class Identifier

  def initialize(name)
    @name = name # string
  end

  def eval
    @name
  end

end

class DataType

  def initialize(data_type)
    @data_type = data_type # string
  end

  def eval
    @data_type
  end

end

class VoidType

  def eval
    "void"
  end

end

class ArithmeticExpr

  def initialize(lh, op, rh)
    @lh = lh	# a_expr/ m_expr
    @op = op	# string
    @rh = rh	# m_expr/ arithmetic_primary
  end

  def eval
    case @op
    when '*' then return (@lh.eval * @rh.eval)
    when '/' then return (@lh.eval / @rh.eval)
    when '+' then return (@lh.eval + @rh.eval)
    when '-' then return (@lh.eval - @rh.eval)
    when '%' then return (@lh.eval % @rh.eval)
    end
  end

end

class ConcatExpr
  # lh is a concat_expr whereas rh is a concat_primary
  def initialize(lh, rh)
    @lh = lh.eval
    @rh = rh.eval
  end

  def eval
    @lh+@rh
  end

end

class IntLiteral

  def initialize (value)
    @value = value # Fixnum
  end

  def eval
    @value
  end

end

class FloatLiteral

  def initialize(value)
    @value = value # Float
  end

  def eval
    @value
  end

end

class BoolLiteral

  def initialize(value)
    @value = value # TrueClass/ FalseClass
  end

  def eval
    @value
  end

end

class StringLiteral

  def initialize(value)
    @value = value # String
  end

  def eval
    @value
  end

end

class ListLiteral

  def initialize(content = [])
    @content = content # list_content
  end

  def eval
    list = @content
  end

end

class Function

  attr_accessor :name, :stmts, :parameters, :return_type

  def initialize(name, stmts, return_type, parameters)
    @name = name
    @stmts = stmts
    @return_type = return_type
    @parameters = parameters
  end

  def eval
    @stmts
  end

end

class FunctionDefinition

  def initialize(data_type, name, stmts, parameters = [])
    @data_type = data_type
    @name = name
    @stmts = stmts
    @parameters = parameters
  end

  def eval

    data_type = @data_type
    name = @name.eval
    parameters = @parameters
    stmts = @stmts

    new_function = Function.new(name, stmts, data_type, parameters)
    @@functions[name] = new_function
  end

end

class FunctionCall

  def initialize(name, parameters = [])
    @parameters = parameters
    @name = name
  end

  def eval

    @@scope.unshift ({})

    function_name = @name.eval
    expected_return_type = @@functions[function_name].return_type

    return_value = nil;

    @parameters.each_with_index do |value, index|

      data_type = @@functions[function_name].parameters[index][0]
      name = @@functions[function_name].parameters[index][1]

      InitializeVar.new(data_type, name, value).eval
    end

    # Handle breaks/ returns
    @@functions[function_name].stmts.each do |stmt|
      stmt_value = stmt.eval
      if (stmt.class == Return or
          stmt.class == Break or
          stmt.class == IfConstruct or
          stmt.class == WhileConstruct or
          stmt.class == ForConstruct)

        case stmt_value
          
        # exit program if break is found in function
        when :break then
          puts "Error: break statement outside compound statement."
          Kernel.exit

        # skip on to next statement
        when :uninterrupted_stmt
          next

        # return if expected data type is void, exit program otherwise
        when :return
          if expected_return_type == "void"
            @@scope.shift
            return nil
          else
            puts "Error: expected return of type \"#{expected_return_type}\"."
            Kernel.exit
          end

        # executes when a returnvalue is received, return the value if it
        # matches the expected data type, exit program otherwise.
        else
          if ( check_type( expected_return_type, stmt_value ) )
            @@scope.shift
            return stmt_value
          else
            puts "Error: wrong return type, expected \"#{expected_return_type}\"."
            Kernel.exit
          end

        end
      end
    end

    if (expected_return_type == "void")
      @@scope.shift
      return_value
    else
      puts "Error: no return found."
      Kernel.exit
    end
  end

end

class IfConstruct

  def initialize(if_stmts)
    @if_stmts = if_stmts
  end

  # returns :break, :return, :uninterrupted_stmt or a given return value
  def eval

    return_status = :condition_false

    @@scope.unshift ({})
    @if_stmts.each do |if_object|
      return_status = if_object.eval

      case return_status

      #break stmt
      when :break then
        @@scope.shift
        return :break

      # return stmt without parameter
      when :return then
        @@scope.shift
        return :return
  
      # condition evaluated to false
      when :condition_false then
        ### run the next if_object
        next

      when :uninterrupted_stmt then
        @@scope.shift
        return :uninterrupted_stmt

      # return stmt with parameter
      else
        @@scope.shift
        return return_status

      end

    end

      # if all if_objects evaluates to false
      @@scope.shift
       return :uninterrupted_stmt

  end

end

class IfObject

  def initialize(stmts, condition = true)
    @stmts =  stmts		# array of stmts
    @condition = condition	# always true for else part
  end

  def eval

    if @condition == true
      condition = @condition
    else
      condition = @condition.eval
    end

    return_status = :uninterrupted_stmt
    
    # when the condition evaluates to true
    if (condition)
#      return_status = :condition_true

      @stmts.each do |stmt|
        stmt_value = stmt.eval

        if (stmt.class == Break or stmt.class == Return)
          return stmt_value

        elsif (stmt.class == IfConstruct or
               stmt.class == WhileConstruct or
               stmt.class == ForConstruct)

          case stmt_value
          when :break then return :break
          when :return then return :return
          when :uninterrupted_stmt then next
          else return stmt_value
          end

        end
      end
      
    else
      return :condition_false
    end
    return :uninterrupted_stmt
  end

end

class WhileConstruct

  def initialize(condition, stmts)
    @condition = condition
    @stmts = stmts
  end

  def eval
    while(true)
      if (@condition.eval)
      
        return_status = :uninterrupted_stmt
        @@scope.unshift ({})
        
        @stmts.each do |stmt|
          stmt_value = stmt.eval

          if (stmt.class == Return or
              stmt.class == Break or
              stmt.class == IfConstruct or
              stmt.class == WhileConstruct or
            stmt.class == ForConstruct)

            case stmt_value
            when :break then
              @@scope.shift
              return :uninterrupted_stmt

            when :return then
              @@scope.shift
              return :return

            when :uninterrupted_stmt then
              next

            # found return with a value
            else
              @@scope.shift
              return stmt_value
            end

          end

        end
        
        @@scope.shift
      else # (@condition.eval)
        return :uninterrupted_stmt
      end
    end
  end

end

class ForConstruct

  def initialize(id, source, stmts)
    @id = id		# identifier
    @source = source	# concat_expr or Range
    @stmts = stmts	# list of Statements
  end

  def eval
    
    id = @id.eval

    # when looping a range
    if @source.class == Array

      first = @source[0].eval
      second = @source[1].eval

      #convert the values to a range object
      if (first <= second)
        source = (first..second)
      else
        puts "Error: minimum value must be given first."
        Kernel.exit
      end

    # on a string literal
    elsif (@source.eval.class == String)
      # split to be able to use each
      source = @source.eval.split(//)
    else
      source = @source.eval
    end

    return_status = :uninterrupted_stmt

    source.each do |element|

      @@scope.unshift ({})
      
      # create each iterations element
      create_new_variable( id, element, get_data_type(element) )

      @stmts.each do |stmt|
        stmt_value = stmt.eval

        if (stmt.class == Return or
            stmt.class == Break or
            stmt.class == IfConstruct or
            stmt.class == WhileConstruct or
            stmt.class == ForConstruct)

          case stmt_value
          when :break then
            @@scope.shift
            return :uninterrupted_stmt
            
          when :return then
            @@scope.shift
            return :return
            
          when :uninterrupted_stmt then
            next
            
          # found return with a value
          else
            @@scope.shift
            return stmt_value

          end # case

        end # if stmt.class...

      end # @stmts.each

      @@scope.shift
    end

    return_status

  end

end

class Return

  def initialize(return_value = nil)
    @return_value = return_value
  end

  def eval
    if (@return_value == nil)
      :return
    else
      @return_value.eval
    end
  end

end

class Break

  def eval
    :break
  end

end

class AndOrTest

  def initialize(lh, op = nil, rh = nil)
    @lh = lh # and_or_test
    @op = op # string
    @rh = rh # not_test
  end

  def eval
    case @op
    when 'and' then return (@lh.eval and @rh.eval)
    when 'or' then return (@lh.eval or @rh.eval)
    end
  end


end

class NotTest

  def initialize(comparison, op = nil)
    @comparison = comparison
    @op = op
  end

  def eval
    if @op
      not @comparison.eval
    else
      @comparison.eval
    end
  end

end

class Comparison

  def initialize(lh, op, rh)
    @lh = lh # expr
    @op = op # comp_operator
    @rh = rh # expr
  end

  def eval

    case @op
    when '==' then return (@lh.eval == @rh.eval)
    when '>=' then return (@lh.eval >= @rh.eval)
    when '<=' then return (@lh.eval <= @rh.eval)
    when '!=' then return (@lh.eval != @rh.eval)
    when '>' then return (@lh.eval > @rh.eval)
    when '<' then return (@lh.eval < @rh.eval)
    end

  end

end

class PrintFunction

  def initialize(value)
    @value = value
  end

  def eval
    value = @value.eval
    print value
    value
  end

end

class PrintlineFunction

  def initialize(value)
    @value = value
  end

  def eval
    value = @value.eval
    puts value
    value
  end

end

class ReadFunction

  def eval
    value = gets
  end

end

class PopFunction

  def initialize(source)
    @source = source # primary
  end

  def eval

    source = @source.eval

    if source.class == Array

      if source.empty?
        puts("Error: list is empty.")
        Kernel.exit
      end

      source.pop
    else
      puts "Error: expected list data type."
      Kernel.exit
    end
  end

end

class AppendFunction

  def initialize(source, value)
    @source = source	# primary
    @value = value	# expr
  end

  def eval

    source = @source.eval
    value = @value.eval

    if source.class == Array
      source << value
    else
      puts "Error: expected list data type."
      Kernel.exit
    end
  end

end

class RemoveFunction

  def initialize(source, index)
    @source = source	# primary
    @index = index	# a_expr
  end

  def eval

    source = @source.eval
    index = @index.eval

    if source.class == Array

      if source.length <= index
        puts "Error: index out of range."
        Kernel.exit
      end

      source.delete_at index
    else
      puts "Error: expected list data type."
      Kernel.exit
    end
  end

end

class ConcatFunction

  def initialize(source, value)
    @source = source	# primary
    @value = value	# primary
  end

  def eval

    source = @source.eval
    value = @value.eval

    if source.class == Array
      source.concat value
    else
      puts "Error: expected list data type."
      Kernel.exit
    end
  end

end

class LengthFunction

  def initialize(source)
    @source = source	# primary
  end

  def eval

    source = @source.eval

    if ( source.class == Array or
         source.class == String )
      source.length
    else
      puts "Error: expected list or string data type."
      Kernel.exit
    end
  end

end

class StringFunction

  def initialize(source)
    @source = source
  end

  def eval

    source = @source.eval

    source.to_s
  end

end

class IntFunction

  def initialize(source)
    @source = source
  end

  def eval
    
    source = @source.eval

    source.to_i

  end

end

class FloatFunction

  def initialize(source)
    @source = source
  end

  def eval
    
    source = @source.eval

    source.to_f

  end

end

################################################################################
# Functions
################################################################################

def check_type(expected_data_type, value)
  case expected_data_type
  when "int"	then return (value.class == Fixnum or value.class == Float)
  when "float"	then return (value.class == Fixnum or value.class == Float)
  when "string"	then return (value.class == String)
  when "list"	then return (value.class == Array)
  when "dict"	then return (value.class == Hash)
  when "bool"	then return (value.class == TrueClass or
                             value.class == FalseClass)
  else 
    puts "Error: datatype of weirdness, wat did u do??"
    Kernel.exit
  end
end

def get_data_type(object) # where object is 5 or "hi" or likewise

  return "int" if object.class == Fixnum
  return "string" if object.class == String
  return "bool" if object.class == TrueClass
  return "bool" if object.class == FalseClass
  return "float" if object.class == Float
  return "list" if object.class == Array
  return "dict" if object.class == Hash

  case object.class

  when Fixnum	  then return "int"
  when String	  then return "string"
  when TrueClass  then return "bool"
  when FalseClass then return "bool"
  when Float	  then return "float"
  when Array	  then return "list"
  when Hash	  then return "dict"
  else return nil
  end
end

def get_variable_scope(variable_name)
  # check local scope first, followed by enclosing scopes
  @@scope.each_with_index do |current_scope, scope_index|
    current_scope.each_key do |current_name|
      if current_name == variable_name
        return scope_index
      end
    end
  end

  # if variable doesn't exist
  return nil
end

def create_new_variable(name, value, data_type)

  new_var = Variable.new()

  new_var.name = name
  new_var.data_type = data_type
  new_var.value = value

  @@scope[0][name] = new_var

end
