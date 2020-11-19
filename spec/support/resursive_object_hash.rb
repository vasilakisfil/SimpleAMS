class KeyNotFound < StandardError
end

class RecursiveObjectHash < Hash
  def method_missing(meth, *_args)
    raise KeyNotFound unless key?(meth.to_s)

    value = send(:[], meth.to_s)
    return value unless value.is_a? Hash

    RecursiveObjectHash.new(value)
  end

  def respond_to_missing?(meth, _)
    key?(meth.to_s) || super
  end
end
