require 'simplecov'

# Load the existing files
Dir.glob(PROJECT_SPECS).each do |spec_file|
  if File.basename(spec_file) != 'init.rb' and File.basename(spec_file) != 'helper.rb'
    # Exclude integration tests by default
    if File.dirname(spec_file).include?('integration') and !ENV["EXTENDED_SPECS"]
      puts "% Skipping spec file : #{spec_file} (define EXTENDED_SPECS to run integration tests)"
      next
    end
    puts "% Using spec file : #{spec_file}"
    require File.expand_path(spec_file)
  end
end
