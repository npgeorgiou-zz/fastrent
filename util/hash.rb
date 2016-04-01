class Hash

  # Dig inside a hash, moving a lever deeper each time. Bail if a property is not a hash
  # return true on successful path following, nil on failure
  def dig(path)

    dig_result = path.split('.').inject(self) { |location, key|
      if (!location.is_a?(Hash))
        return nil
      end
      location.has_key?(key) ? location[key] : nil
    }

    return dig_result
  end

  def chunk (chunk_size)
    array = []
    i = 0
    c_i = -1
    self.each do |k, v|

      if i === 0
        chunk = []
        array << chunk
      else
        chunk = array[c_i]
      end

      if chunk.size === chunk_size
        chunk = []
        array << chunk
        c_i = c_i + 1
      end

      h = Hash.new()
      h[k] = v
      chunk << h

      i = i + 1
    end


    return array
  end
end