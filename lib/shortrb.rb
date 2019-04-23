require "shortrb/version"

using(Module.new do
  refine RubyVM::AbstractSyntaxTree::Node do
    def [](idx)
      children[idx]
    end
  end
end)

module Shortrb
  class AstToStr
    def self.convert(root)
      self.new(root).convert
    end

    def initialize(root)
      @root = root
      @stack = []
    end

    def convert
      _convert(@root)
    end

    private def _convert(node)
      @stack.push node
      res = __send__(:"on_#{node.type}", node)
      @stack.pop
      res
    end

    private def parent
      @stack[-2]
    end

    private def on_SCOPE(node)
      args =
        if parent&.type == :ITER && !node[0].empty?
          "|#{node[0].map(&:to_s).join(',')}|"
        else
          ""
        end
      args + _convert(node[2])
    end

    private def on_CLASS(node)
      "class #{_convert node[0]};#{_convert node[2]};end"
    end

    private def on_COLON2(node)
      parent, this = node.children
      if parent
        "#{_convert parent}::#{this}"
      else
        this.to_s
      end
    end

    private def on_BEGIN(node)
      # XXX: is it ok?
      ""
    end

    private def on_BLOCK(node)
      node.children
        .map { |child| _convert(child) }
        .reject { |str| str.empty? }
        .join(';')
    end

    private def on_VCALL(node)
      node[0].to_s
    end

    private def on_FCALL(node)
      method_name = node[0]
      return method_name unless node[1]
      args = _convert node[1]
      if space_necessary_between_method_name_and_args?(method_name.to_s, args)
        "#{method_name} #{args}"
      else
        "#{method_name}#{args}"
      end
    end

    private def on_CALL(node)
      method_name = +"#{_convert node[0]}.#{node[1]}"
      return method_name unless node[2]
      args = _convert(node[2])
      if space_necessary_between_method_name_and_args?(method_name.to_s, args)
        "#{method_name} #{args}"
      else
        "#{method_name}#{args}"
      end
    end

    private def on_OPCALL(node)
      # TODO: multi args
      "#{_convert node[0]}#{node[1]}#{_convert node[2]}"
    end

    private def on_QCALL(node)
      method_name = +"#{_convert node[0]}&.#{node[1]}"
      return method_name unless node[2]
      args = _convert(node[2])
      if space_necessary_between_method_name_and_args?(method_name.to_s, args)
        "#{method_name} #{args}"
      else
        "#{method_name}#{args}"
      end
    end

    private def on_ITER(node)
      "#{_convert node[0]}{#{_convert node[1]}}"
    end

    private def on_ARRAY(node)
      res = node.children.compact.map { |child| _convert child }.join(',')
      if parent.type == :FCALL || parent.type == :CALL || parent.type == :OPCALL || parent.type == :QCALL
        res
      else
        "[#{res}]"
      end
    end

    private def on_ZARRAY(node)
      return '[]'
    end

    private def on_LIT(node)
      node.children.first.inspect
    end

    private def on_STR(node)
      str = node.children.first
      if str.size == 1 && str !~ /\s/
        "?#{str}"
      else
        str.inspect
      end
    end

    private def on_LASGN(node)
      "#{node[0]}=#{_convert node[1]}"
    end

    alias on_GASGN on_LASGN
    alias on_IASGN on_LASGN
    alias on_CVASGN on_LASGN

    private def on_LVAR(node)
      "#{node[0]}"
    end

    alias on_GVAR on_LVAR
    alias on_IVAR on_LVAR
    alias on_CVAR on_LVAR

    private def space_necessary_between_method_name_and_args?(method_name, args)
      # TODO: is it right?
      return false if method_name.end_with?('?', '!')
      return args.match?(/\A[[:alnum:]]/)
    end
  end
end
