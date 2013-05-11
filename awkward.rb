require '~/awkward/parser.rb'

awkward = Awkward.new()
awkward.log false

if (ARGV.length == 1)
  file_name = ARGV[0];
  if (/\A.+\.aww\z/ =~ file_name)
    awkward.parse_file(file_name)
  else
    puts "file extension must be .aww"
  end
else
  awkward.parse
end

