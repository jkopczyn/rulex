module Rulex
  module Rex
    class Reader
      def initialize
        @content = []
        @latex_reader = Rulex::Tex::Reader.new
      end

      def read str
        eval str
      end

      def raw str
        new_node = {type: :raw, text: str }
        @content << new_node
      end

      def tex str
        new_node = {type: :tex, children: @latex_reader.read(str)}
        @content << new_node
      end

      def export
        @content
      end
    end
  end
end