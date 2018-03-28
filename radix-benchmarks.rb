#
# For testing.
#

require 'benchmark'

require_relative 'radix-test'
require_relative 'radix-redux'


class Range

  def to_a
    ret = [ ]
    self.each { |i| ret.push(i) }
    return ret
  end

end


rad_h = RadixTreeH.new
rad_a = RadixTreeA.new

strings = ('a'..'z').to_a
times = 100000


def get_strings( strings, n )
  ret = [ ]

  (0..n).each do |i|
    ret.push(strings.sample(Random::DEFAULT.rand(strings.length)))
  end

  return ret
end


Benchmark.bmbm do |x|

  str = get_strings(strings, times)

  x.report("add H:") do
    str.each { |s| rad_h.add(s.join) }
  end

  x.report("add A:") do
    str.each { |s| rad_a.add(s.join) }
  end

  x.report("get H:") do
    str.each { |s| rad_h.get(s.join) }
  end

  x.report("get A:") do
    str.each { |s| rad_a.get(s.join) }
  end

  x.report("del H:") do
    str.each { |s| rad_h.del(s.join) }
  end

  x.report("del A:") do
    str.each { |s| rad_a.del(s.join) }
  end

end
