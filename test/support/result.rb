module TomeTest
  class Result
    attr_reader :data, :error_message, :exit_code

    def initialize(data: nil, error_message: nil, exit_code: 0)
      @data = data
      @error_message = error_message
      @exit_code = exit_code
    end

    def success?
      @exit_code == 0 && @error_message.nil?
    end

    def failure?
      !success?
    end

    def method_missing(name, *args)
      key = name.to_s
      if @data.is_a?(Hash)
        return @data[key] if @data.key?(key)
        return @data[name.to_sym] if @data.key?(name.to_sym)
      end
      super
    end

    def respond_to_missing?(name, include_private = false)
      if @data.is_a?(Hash)
        return true if @data.key?(name.to_s) || @data.key?(name.to_sym)
      end
      super
    end

    def to_s
      "#<Result success=#{success?} data=#{@data.inspect} error=#{@error_message.inspect}>"
    end
  end
end
