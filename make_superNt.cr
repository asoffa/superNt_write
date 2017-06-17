require "option_parser"

ROOTCORE_DIR = "/data/uclhc/uci/user/asoffa/projects/ss3l/productions/susyNt_n0232/superNt_write/susynt-read/"


# extension for job name => flags
MC_BKG_RUN_MODE_MAP    = { "mc_bkg"    => "" }
DATA_RUN_MODE_MAP      = { "data"      => "-D" }
MC_SIGNAL_RUN_MODE_MAP = { "mc_signal" => "" }


def condorScript(executable)
    <<-SCRIPT
       universe = vanilla
       +local=true
       +site_local=false
       +sdsc=false
       +uc=false
       executable = #{executable}
       arguments = $ENV(ARGS)
       should_transfer_files = YES
       when_to_transfer_output = ON_EXIT
       use_x509userproxy = True
       notification = Never
       queue
       SCRIPT
end


def bashScript(cmd)
    <<-SCRIPT
       #!/bin/bash
       
       runDir=$PWD
       
       cd #{ROOTCORE_DIR}
       echo "Now in $(pwd)"
       echo "Setting up RootCore"
       export ATLAS_LOCAL_ROOT_BASE=/cvmfs/atlas.cern.ch/repo/ATLASLocalRootBase
       source ${ATLAS_LOCAL_ROOT_BASE}/user/atlasLocalSetup.sh
       
       lsetup fax --skipConfirm
       source ./bash/setup_root.sh
       #rcSetup
       #source ./RootCore/scripts/setup.sh
       source ./RootCore/local_setup.sh
       #source setupRestFrames.sh
       echo "Using root $(root-config --version) from $(which root)"
       
       echo Starting $(date)
       
       cd $runDir
       
       #{cmd}
       
       SCRIPT
end


def runJob(cmd, jobName)
    condorName = "#{jobName}.condor"
    bashName   = "#{jobName}.sh"

    File.open(bashName, "w") { |f| f.puts bashScript(cmd) }
    File.open(condorName, "w") { |f| f.puts condorScript(bashName) }

    system "condor_submit #{condorName}"
end


def getDsid(sample : String) : String?
    sample.split "." do |piece|
        piece.split "_" do |subpiece|
            subpiece = subpiece.rstrip "/"
            return subpiece if {6, 8}.includes?(subpiece.size) && subpiece.to_f?
        end
    end
    nil
end

#-------------------------------------------------------------------------------

input          = nil
nEntries       = -1
run?           = false
submit?        = false

# run modes:
data?          = false
mcBkg?         = false
signal?        = false


OptionParser.parse! do |parser|
    parser.banner = "usage: submit_condor_run_ss3l_susynt [args]"
    parser.on("-R", "--run", "run jobs locally rather than do a dry run (see also --submit/-s)") { run? = true }
    parser.on("-S", "--submit", "submit jobs to Condor rather than do a dry run or run locally (see also --run/-r") { submit? = true }
    parser.on("-i INPUT", "--input INPUT", "specify input (can be a .root file, directory, or .txt file)") { |i| input = i }
    parser.on("-d", "--data", "specify data mode (use when running data)") { data? = true }
    parser.on("-m", "--mcBkg", "specify Monte Carlo background mode (use when running Monte Carlo backgrounds, default)") { mcBkg? = true }
    parser.on("-n N_ENTRIES", "--nEntries N_ENTRIES", "specify number of entries (default: -1 for all entries") { |n| nEntries = n.to_i? }
    #parser.on("-s", '--site', "set cluster option [1:brick-only, 2:brick+local, 3:brick+local+SDSC, 4:brick+local+SDSC+UCs] (default: 1)") { |opt| siteOpt = opt }
    parser.on("-s", "--signal", "specify signal mode (use when running Monte Carlo signal samples") { signal? = true }
    parser.on("-h", "--help", "show this help") { puts parser; exit }
end

if ! input
    puts "--input/-i is a required option"
    exit 1
end

if ! nEntries
    puts "`N_ENTRIES` must be an integer when using `--nEntries/-n N_ENTRIES`"
    exit 1
end


nModes = {mcBkg?, signal?, data?}.reduce(0) { |n, mode| mode==true ? n + 1 : n }

if nModes == 0
    mcBkg? = true
    nModes = 1
end

if nModes != 1
    puts "Exactly one of --mc/-m, --signal/-s, or --data/-d must be specified (--mc/-m is the default)"
    exit 1
end

mode = ""
modeFlags = ""
if mcBkg?
    mode = "mc_bkg"
elsif signal?
    mode = "mc_signal"
elsif data?
    mode = "data"
    modeFlags = "-D"
else
    puts "Exactly one of --mc/-m, --signal/-s, or --data/-d must be specified (--mc/-m is the default)"
    exit 1
end


dsid = getDsid(input.as String)

outputDir = dsid ? "out_#{mode}_#{dsid}" : "out_#{mode}"
jobName   = dsid ? "run_#{mode}_#{dsid}" : "run_#{mode}"

cmd  = "run_ss3l_susynt -i #{File.expand_path input.as(String)}/ #{modeFlags}"
cmd += " -n #{nEntries}" if nEntries.as(Int) > -1
cmd += " |& tee stdout.log"

puts
puts cmd
puts

if run? || submit?
    startDir = Dir.current
    Dir.mkdir_p outputDir
    Dir.cd outputDir
    if submit?
        runJob cmd, jobName
    else
        system cmd
    end
    Dir.cd startDir
else 
    puts "This was a dry run. To run jobs locally or submit job to Condor, add the --run/-r or --submit/-s option, respectively."
    puts "The output directory would be #{outputDir}"
    puts
end

