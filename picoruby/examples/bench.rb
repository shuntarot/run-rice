# Times a few small jobs with the cycle and instruction counters. Both count
# the core, so the numbers are cycles and instructions of the whole run. The
# counters Ruby sees have 30 bits, so keep each job under 20 seconds at 50 MHz.
def fib(n)
  n < 2 ? n : fib(n - 1) + fib(n - 2)
end

def bench(name)
  c0 = cycles
  i0 = instret
  yield
  c = (cycles - c0) & 0x3fffffff
  i = (instret - i0) & 0x3fffffff
  cpi = "#{c / i}.#{(c % i) * 10 / i}"
  puts "#{name}: #{c / khz} ms, #{c} cycles, #{i} instructions, CPI #{cpi}"
end

bench("fib(15)")        { fib(15) }
bench("times 3000")     { n = 0; 3000.times { n += 1 } }
bench("while 3000")     { n = 0; i = 0; while i < 3000; n += 1; i += 1; end }
bench("array 1000")     { a = []; 1000.times {|i| a << i * 2 }; a.map {|x| x + 1 } }
bench("string 500")     { s = ""; 500.times {|i| s << "ab" }; s.size }
bench("hash 300")       { h = {}; 300.times {|i| h[i] = i }; h.size }
