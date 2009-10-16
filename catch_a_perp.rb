#!/usr/bin/env ruby

if ARGV[1] == 'GO'
  pid = Kernel.fork do
    
  end
  
  Process.detach(pid)
end