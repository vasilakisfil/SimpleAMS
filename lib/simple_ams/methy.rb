module SimpleAMS::Methy
  def self.of(hash = {})
    m = Module.new
    hash.each do |key, value|
      m.send(:define_method, key){ value }
    end

    return m
  end
end
