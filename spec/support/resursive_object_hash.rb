class KeyNotFound < StandardError
end

class RecursiveObjectHash < Hash
  def method_missing(meth, *args)
    if self.key?(meth.to_s)
      value = self.send(:[], meth.to_s)
      return value unless value.is_a? Hash
      return RecursiveObjectHash.new(value)
    else
      raise KeyNotFound
    end
  end
end
