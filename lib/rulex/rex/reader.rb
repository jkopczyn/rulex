module Rulex
  module Rex
    class Reader

      def initialize
        @content = []
        @content_stack = [@content]
        @latex_reader = Rulex::Tex::Reader.new
      end

      def read *args, &block
        if args.length == 1
          read_rex args.first
        elsif block
          instance_eval &block
        end
      end

      def read_rex str
        instance_eval rex_to_ruby str
      end

      # There are a few characters ('\\', '\[' and '\]') that %q[] escapes anyway
      def rex_to_ruby str
        str.gsub(/<##(((?!##>).)+)##>/) { |m| "raw %q[" + $1.gsub("\\","\\\\\\\\") + "]"}
      end

      def add_node_to_content node
        @content_stack.last << node
      end

      def raw str
        add_node_to_content(type: :text, text: str)
      end

      def tex str
        add_node_to_content(type: :tex, children: @latex_reader.read(str))
      end

      def import filepath
        read File.open(filepath).read
      end

      def export
        @content
      end

      def build_tex_command(name, params)
        case params.length
        when 1
          {type: :command, name: name, arguments: params} 
        when 2
          first = params[0]
          second = params[1]
          if Array === params[0] && Array === params[1]
            {type: :command, name: name, arguments: second, options: first}
          elsif String === params[0] && String === params[1]
            {type: :command, name: name, arguments: [first, second]}
          else
            error "something is not quite right with the parameters"
          end
        else
          error "wrong number of params"
        end
      end

      def tex_command(name, params)
        add_node_to_content build_tex_command name, params
      end

      def depth
        @content_stack.length - 1
      end

      def tex_environment(name, *args, &block)
        new_node = {type: :environment, name: name, arguments: args}
        @content_stack.push []
        read &block
        new_node.merge!(children: @content_stack.pop)
        add_node_to_content new_node
      end

      def method_missing(m_id, *args, &block) 
        if block
          tex_environment(m_id, *args, &block)
        elsif /pure_([a-zA-Z]+)/.match(m_id)
          Rulex::Tex::Writer.to_str(build_tex_command($1,args))
        else
          tex_command(m_id, args)
        end
      end

    end
  end
end
