desc "show a todolist from all the TODO tags in the source"
task :todo do
  yellow = "\e[33m%s\e[0m"

  Dir.glob('{controller,model,layout,view,spec}/**/*.{rb,xhtml}') do |file|
    lastline = todo = comment = long_comment = false

    File.readlines(file).each_with_index do |line, lineno|
      lineno      += 1
      comment      = line =~ /^\s*?#.*?$/
      long_comment = line =~ /^=begin/
      long_comment = line =~ /^=end/

      todo = true if line =~ /TODO|FIXME|THINK/ and (long_comment or comment)
      todo = false if line.gsub('#', '').strip.empty?
      todo = false unless comment or long_comment

      if todo
        unless lastline and lastline + 1 == lineno
          puts
          puts yellow % "#{file}#L#{lineno}"
        end

        l = line.strip.gsub(/^#\s*/, '')
        print '  ' unless l =~ /^-/
        puts l
        lastline = lineno
      end
    end # File.readlines
  end
end # task :todo
