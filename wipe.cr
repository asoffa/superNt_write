require "option_parser"

def wipe(subDir : String)
    baseDir = "../datasets_superNt/#{subDir}"
    
    if ! Dir.exists? baseDir
        puts "Directory not found: `#{baseDir}`"
    else
        system "rm -rf #{baseDir}/out_*"
        puts "`out_*` directories in `#{baseDir}` have been wiped"
    end
end

#-------------------------------------------------------------------------------

if ARGV.size < 1 || ARGV[0].starts_with? '-'
    puts "usage: wipe <directory>"
    puts "             ^^^ directory in `../datasets_superNt/` to be wiped"
    exit
end

ARGV.each do |subDir|
    wipe subDir
end

