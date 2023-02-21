if {$::argc == 4} {
    set area [lindex $argv 0]
    set nNodes [lindex $argv 1]
    set nFlows [lindex $argv 2]
    set packetsPsec [lindex $argv 3]
    # set linkBandwidth [lindex $argv 4]
    # set bottleneckBandwidth [lindex $argv 5]
    # puts "$t"
} else {
    puts "Usage :  ns <fileName> <area> <nNodes> <nFlows> <packetsPsec>"
    exit
}

# puts "finished $bottleneckBandwidth"

#Create a simulator object
set ns [new Simulator]
# set delay [expr (1/packetsPsec)]
# puts "$delay"

#Define different colors for data flows (for NAM)
# $ns color 1 Blue
# $ns color 2 Red

#Open the NAM file and trace file
set nam_file [open animation.nam w]
set trace_file [open trace.tr w]
$ns namtrace-all $nam_file
$ns trace-all $trace_file

#Create nodes
for {set i 0} {$i < $nNodes} {incr i} {
    set node($i) [$ns node]
}
set routerA [$ns node]
set routerB [$ns node]
set temp [expr ($nNodes/2)]
# puts "$temp"

#Create links between the nodes
for {set i 0} {$i < $temp} {incr i} {
    $ns duplex-link $node($i) $routerA 10Mb 10ms DropTail
    $ns duplex-link $node([expr ($i + $temp)]) $routerB 10Mb 10ms DropTail
    # puts "Flag $i"
}

Queue/PI set bytes_ false
Queue/PI set queue_in_bytes_ false
Queue/PI set a_ 0.5
Queue/PI set b_ 0.7
Queue/PI set w_ 170
Queue/PI set qref_ 20
Queue/PI set mean_pktsize_ 1000
Queue/PI set setbit_ false
Queue/PI set prob_ 0.2
Queue/PI set curq_ 0

Queue/PI set IAPI_enable_ false
Queue/PI set e_thres_ 3
Queue/PI set kp_ 0.00014723
Queue/PI set k1_ 0.5
Queue/PI set ki0_ 0.0000004277
# bottleneck link
$ns duplex-link $routerA $routerB 1Mb 20ms PI

# ns <link-type> <node1> <node2> <bandwidht> <delay> <queue-type-of-node2>

#Set Queue Size of link (n2-n3) to 10
$ns queue-limit $routerA $routerB 20

#Give node position (for NAM)
#$ns duplex-link-op $n0 $n2 orient right-down
#$ns duplex-link-op $n1 $n2 orient right-up
#$ns duplex-link-op $n2 $n3 orient right

#Monitor the queue for link (n2-n3). (for NAM)
$ns duplex-link-op $routerA $routerB queuePos 1.0


#Setup a TCP connection
#Setup flows
for {set i 0} {$i < $nFlows} {incr i} {
    set source [expr int((floor(($nNodes/2) * rand())))]
    set sink [expr int(((floor($nNodes/2) * rand())) + $temp)]
    # puts "$source"
    # puts "$sink"

    set tcpReno [new Agent/TCP/Reno]
    set tcp_sink [new Agent/TCPSink]

    $ns attach-agent $node($source) $tcpReno
    $ns attach-agent $node($sink) $tcp_sink
    $ns connect $tcpReno $tcp_sink
    $tcpReno set fid_ $i

    set ftp [new Application/FTP]
    $ftp attach-agent $tcpReno

    $ns at 1.0 "$ftp start"
}


# #Setup a UDP connection
# #Setup another flow
# set udp [new Agent/UDP]
# $udp set class_ 2
# $ns attach-agent $n1 $udp
# set null [new Agent/Null]
# $ns attach-agent $n3 $null
# $ns connect $udp $null
# $udp set fid_ 2

# #Setup a CBR over UDP connection
# set cbr [new Application/Traffic/CBR]
# $cbr attach-agent $udp
# $cbr set type_ CBR
# $cbr set packet_size_ 1000
# $cbr set rate_ 1mb
# $cbr set random_ false

#Schedule events for the CBR and FTP agents
# $ns at 0.1 "$cbr start"
# $ns at 1.0 "$ftp start"
# $ns at 4.0 "$ftp stop"
# $ns at 4.5 "$cbr stop"

#Detach tcp and sink agents (not really necessary)
# for {set i 0} {$i < $nNodes} {incr i} {
#     $ns at 50.0 "$node($i) reset"
# }

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

#Define a 'finish' procedure
proc finish {} {
    global ns nam_file trace_file
    $ns flush-trace 
    #Close the NAM trace file
    close $nam_file
    close $trace_file
    #Execute NAM on the trace file
    # exec nam out.nam &
    exit 0
}

#Call the finish procedure after 5 seconds of simulation time
$ns at 50 "finish"
# $ns at 50.2 "halt_simulation"


#Run the simulation
puts "Simulation Starting"
$ns run
