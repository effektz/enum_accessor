module EnumAccessor
  class Configuration

    attr_accessor :start_index

    def initialize
      @start_index = 0
    end

    def start_index=(index)
      @start_index = index.to_i == 1 ? 1 : 0
    end

  end
end
