# A task that never waits: the other one cannot run until this one is done,
# because nothing interrupts it.
n = 0
200000.times { n += 1 } if false
i = 0
while i < 100000
  i += 1
end
puts "busy done"
