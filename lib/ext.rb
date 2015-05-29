class Object
  def first_only(ops=nil,&b)
    res = ops ? where(ops) : self
    if res.kind_of?(Class)
      res = all
    end

    if block_given?
      res = res.select(&b)
    end

    if res.count == 1
      res.first
    else
      raise "Bad Size #{res.count} (Orig #{count}) #{ops.inspect} | #{caller.first}"
    end
  end

  def first_at_least(ops=nil)
    res = ops ? where(ops) : self
    if res.kind_of?(Class)
      res = all
    end

    if res.count >= 1
      res.first
    else
      raise "Bad Size #{res.count} (Orig #{count}) #{ops.inspect} | #{caller.first}"
    end
  end

  def first_at_most(ops=nil)
    res = ops ? where(ops) : self
    if res.kind_of?(Class)
      res = all
    end

    if res.count <= 1
      res.first
    else
      raise "Bad Size #{res.count} (Orig #{count}) #{ops.inspect} | #{caller.first}"
    end
  end
end

class MakeError
  class << self
    def run
      raise 'MakeError intentionally threw an exception'
    end
  end
end

class Hash
  def with_keys(*ks)
    res = {}
    ks.each do |key|
      res[key] = self[key]
    end
    res
  end

  def each_sorted_by_value_desc(num=nil,&b)
    to_a.sort_by { |x| x[1] }.reverse.each_with_index do |a,i|
      return if num && num <= i
      yield *a
    end
  end
end

class Numeric
  def to_s_perc
    num = (to_f * 100.0).round(1)
    #num = num.to_i if num == num.to_i
    "#{num}%"
  end
end

class Object
  def id_str
    id.to_s
  end
end
