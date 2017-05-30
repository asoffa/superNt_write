require "option_parser"

ROOTCORE_DIR = "/data/uclhc/uci/user/asoffa/projects/ss3l/productions/susyNt_n0232/superNt_write/susynt-read/"


# extension for job name => flags
MC_BKG_RUN_MODE_MAP    = { "mc_bkg"    => "" }
DATA_RUN_MODE_MAP      = { "data"      => "" }
MC_SIGNAL_RUN_MODE_MAP = { "mc_signal" => "" }

FAKES_AND_QFLIP_RUN_MODE_MAP = {

    "qflip"       => "-Q",

    "fakes_11"    => "-F 11",
    "fakes_011"   => "-F 011",
    "fakes_101"   => "-F 101",
    "fakes_110"   => "-F 110",
    "fakes_111"   => "-F 111",

    #"fakes_0011"  => "-F 0011",
    #"fakes_0101"  => "-F 0101",
    #"fakes_0110"  => "-F 0110",
    #"fakes_0111"  => "-F 0111",
    #"fakes_1001"  => "-F 1001",
    #"fakes_1010"  => "-F 1010",
    #"fakes_1011"  => "-F 1011",
    #"fakes_1100"  => "-F 1100",
    #"fakes_1101"  => "-F 1101",
    #"fakes_1110"  => "-F 1110",
    #"fakes_1111"  => "-F 1111",

    #"fakes_00011" => "-F 00011",
    #"fakes_00101" => "-F 00101",
    #"fakes_00110" => "-F 00110",
    #"fakes_00111" => "-F 00111",
    #"fakes_01001" => "-F 01001",
    #"fakes_01010" => "-F 01010",
    #"fakes_01011" => "-F 01011",
    #"fakes_01100" => "-F 01100",
    #"fakes_01101" => "-F 01101",
    #"fakes_01110" => "-F 01110",
    #"fakes_01111" => "-F 01111",
    #"fakes_10001" => "-F 10001",
    #"fakes_10010" => "-F 10010",
    #"fakes_10011" => "-F 10011",
    #"fakes_10100" => "-F 10100",
    #"fakes_10101" => "-F 10101",
    #"fakes_10110" => "-F 10110",
    #"fakes_10111" => "-F 10111",
    #"fakes_11000" => "-F 11000",
    #"fakes_11001" => "-F 11001",
    #"fakes_11010" => "-F 11010",
    #"fakes_11011" => "-F 11011",
    #"fakes_11100" => "-F 11100",
    #"fakes_11101" => "-F 11101",
    #"fakes_11110" => "-F 11110",
    #"fakes_11111" => "-F 11111",
}


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
test?          = false

# run modes:
mcBkg?         = false
fakesAndQflip? = false
signal?        = false
data?          = false


OptionParser.parse! do |parser|
    parser.banner = "usage: submit_condor_run_ss3l_susynt [args]"
    parser.on("-R", "--run", "run jobs locally rather than do a dry run (see also --submit/-s)") { run? = true }
    parser.on("-S", "--submit", "submit jobs to Condor rather than do a dry run or run locally (see also --run/-r") { submit? = true }
    parser.on("-i INPUT", "--input INPUT", "specify input (can be a .root file, directory, or .txt file)") { |i| input = i }
    parser.on("-d", "--data", "specify data mode (use when running data)") { data? = true }
    parser.on("-f", "--fakesAndQflip", "specify fakesAndQflip mode (use when running fakes + qflip") { fakesAndQflip? = true }
    parser.on("-m", "--mcBkg", "specify Monte Carlo background mode (use when running Monte Carlo backgrounds, default)") { mcBkg? = true }
    parser.on("-n N_ENTRIES", "--nEntries N_ENTRIES", "specify number of entries (default: -1 for all entries") { |n| nEntries = n.to_i? }
    #parser.on("-s", '--site', "set cluster option [1:brick-only, 2:brick+local, 3:brick+local+SDSC, 4:brick+local+SDSC+UCs] (default: 1)") { |opt| siteOpt = opt }
    parser.on("-s", "--signal", "specify signal mode (use when running Monte Carlo signal samples") { signal? = true }
    parser.on("-t", "--test", "run over only one input file") { test? = true }
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


nModes = {mcBkg?, fakesAndQflip?, signal?, data?}.reduce(0) { |n, mode| mode==true ? n + 1 : n }

if nModes == 0
    mcBkg? = true
    nModes = 1
end

if nModes != 1
    puts "Exactly one of --mc/-m, --fakesAndQflip/-f, --signal/-s, or --data/-d must be specified (--mc/-m is the default)"
    exit 1
end


dsid = getDsid(input.as String)

runModeMap = if mcBkg?
                 MC_BKG_RUN_MODE_MAP
             elsif fakesAndQflip?
                 FAKES_AND_QFLIP_RUN_MODE_MAP
             elsif signal?
                 MC_SIGNAL_RUN_MODE_MAP
             elsif data?
                 DATA_RUN_MODE_MAP
             else
                 raise "ERROR: unable to determine run mode map"
             end

runModeMap.each do |mode, modeFlags|
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

    break if test?
end

