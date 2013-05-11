require './parser.rb'

awkward = Awkward.new()
awkward.log false

if (ARGV.length == 1)
  file_name = ARGV[0];
  awkward.parse_file(file_name)
else
  awkward.parse
end

