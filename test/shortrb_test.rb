require 'shortrb'
require 'minitest/autorun'

class AstToStrTest < Minitest::Test

  # classes

  def test_class
    # TODO: it should be "class A;end"
    assert_ast_to_str "class A;;end", <<~RUBY
      class A
      end
    RUBY
  end

  def test_class_with_content
    assert_ast_to_str "class A;x;y;end", <<~RUBY
      class A
        x
        y
      end
    RUBY
  end

  # method calls

  def test_vcall
    assert_ast_to_str "x", "x"
  end

  def test_fcall
    assert_ast_to_str "x y", "x y"
    assert_ast_to_str "x y,z", "x y, z"
    assert_ast_to_str "x y", "x(y)"
    assert_ast_to_str "x@y", "x(@y)"
  end

  def test_call
    assert_ast_to_str "x.y", "x.y"
    assert_ast_to_str "x.y z", "x.y(z)"
    assert_ast_to_str "x.y@z", "x.y(@z)"
  end

  def test_iter
    assert_ast_to_str "x{y}", "x { y }"
    assert_ast_to_str "x{|i|y}", "x { |i| y }"
  end

  # operators

  def test_op
    assert_ast_to_str "a+b", "a + b"
  end

  # conditions

  # literals

  def test_zarray
    assert_ast_to_str '[]', '[ ]'
  end

  def test_array
    assert_ast_to_str "[x]", "[ x ]"
    assert_ast_to_str "[x,y]", "[ x, y ]"
    assert_ast_to_str "[x,y,z]", "[x, y, z]"
  end

  def test_int
    assert_ast_to_str "1", "1"
  end

  def test_float
    assert_ast_to_str "1.1", "1.1"
  end

  def test_string
    assert_ast_to_str '"foo"', "'foo'"
    assert_ast_to_str '"foo"', '"foo"'
  end

  def test_symbol
    assert_ast_to_str ':foo', ':foo'
  end

  # assigns

  def test_lasgn
    assert_ast_to_str 'a=1', 'a = 1'
  end

  def test_gasgn
    assert_ast_to_str '$a=1', '$a = 1'
  end

  def test_iasgn
    assert_ast_to_str '@a=1', '@a = 1'
  end

  def test_cvasgn
    assert_ast_to_str '@@a=1', '@@a = 1'
  end

  # variable references

  def test_lvar
    assert_ast_to_str 'a=1;p a', 'a = 1; p a'
  end

  def test_gvar
    assert_ast_to_str '$a=1;p$a', '$a = 1; p $a'
  end

  def test_ivar
    assert_ast_to_str '@a=1;p@a', '@a = 1; p @a'
  end

  def test_cvar
    assert_ast_to_str '@@a=1;p@@a', '@@a = 1; p @@a'
  end

  # helpers

  def assert_ast_to_str(expected, original)
    root = RubyVM::AbstractSyntaxTree.parse(original)
    assert_equal expected, Shortrb::AstToStr.convert(root)
  end
end
