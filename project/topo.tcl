# simulator

if {$::argc == 3} {
    set area [lindex $argv 0]
    set nNodes [lindex $argv 1]
    set nFlows [lindex $argv 2]
    # puts "$t"
} else {
    puts "Usage :  ns <fileName> <area> <nNodes> <nFlows>"
    exit
}

set ns [new Simulator]

set nCols 8

puts "$area"
# set area 500
# set nNodes 40 
# set nFlows 20

# ======================================================================
# Define options

set val(chan)         Channel/WirelessChannel  ;# channel type
set val(prop)         Propagation/TwoRayGround ;# radio-propagation model
set val(ant)          Antenna/OmniAntenna      ;# Antenna type
set val(ll)           LL                       ;# Link layer type
set val(ifq)          Queue/DropTail/PriQueue  ;# Interface queue type
set val(ifqlen)       50                       ;# max packet in ifq
set val(netif)        Phy/WirelessPhy          ;# network interface type
set val(mac)          Mac/802_11               ;# MAC type
set val(rp)           AODV                     ;# ad-hoc routing protocol 
set val(nn)           $nNodes                       ;# number of mobilenodes
# =======================================================================

# trace file
set trace_file [open trace.tr w]
$ns trace-all $trace_file

# nam file
set nam_file [open animation.nam w]
$ns namtrace-all-wireless $nam_file $area $area

# topology: to keep track of node movements
set topo [new Topography]
$topo load_flatgrid $area $area ;# 500m x 500m area


# general operation director for mobilenodes
create-god $val(nn)


# node configs
# ======================================================================

# $ns node-config -addressingType flat or hierarchical or expanded
#                  -adhocRouting   DSDV or DSR or TORA
#                  -llType	   LL
#                  -macType	   Mac/802_11
#                  -propType	   "Propagation/TwoRayGround"
#                  -ifqType	   "Queue/DropTail/PriQueue"
#                  -ifqLen	   50
#                  -phyType	   "Phy/WirelessPhy"
#                  -antType	   "Antenna/OmniAntenna"
#                  -channelType    "Channel/WirelessChannel"
#                  -topoInstance   $topo
#                  -energyModel    "EnergyModel"
#                  -initialEnergy  (in Joules)
#                  -rxPower        (in W)
#                  -txPower        (in W)
#                  -agentTrace     ON or OFF
#                  -routerTrace    ON or OFF
#                  -macTrace       ON or OFF
#                  -movementTrace  ON or OFF

# ======================================================================

$ns node-config -adhocRouting $val(rp) \
                -llType $val(ll) \
                -macType $val(mac) \
                -ifqType $val(ifq) \
                -ifqLen $val(ifqlen) \
                -antType $val(ant) \
                -propType $val(prop) \
                -phyType $val(netif) \
                -topoInstance $topo \
                -channelType $val(chan) \
                -agentTrace ON \
                -routerTrace ON \
                -macTrace OFF \
                -movementTrace OFF

# create nodes
set row 0
set col 0
for {set i 0} {$i < $val(nn) } {incr i} {
    for {set j 0} {$j < $nCols && $i < $val(nn)} {incr j} {
        set node($i) [$ns node]
        $node($i) random-motion 1       ;# disable random motion

        $node($i) set X_ [expr ($area * $row * 5) / $val(nn)]
        $node($i) set Y_ [expr ($area * $col * 5) / $val(nn)]
        $node($i) set Z_ 0

        $ns initial_node_pos $node($i) 20
        #set rand_x [expr (floor(($area) * rand()))]
        #set rand_y [expr (floor(($area) * rand()))]
        set t [expr (rand())]
        #puts "$t"
        set rand_x [expr ($area * rand())]
        set rand_y [expr ($area * rand())]
        set rand_velocity [expr (1 + round(4 * rand ()))]
        #puts "$rand_velocity"
        #puts "$rand_x"
        #puts "$rand_y"
        $ns at 2.0 "$node($i) setdest $rand_x $rand_y $rand_velocity"
        incr i
        incr col
    }
    set col 0
    incr row
    incr i -1
} 


# Traffic
set val(nf)         $nFlows                ;# number of flows
set sink [expr int((floor($val(nn) * rand())))]
# puts "Selected Sink $sink"

for {set i 0} {$i < $val(nf)} {incr i} {
    set source [expr int((floor($val(nn) * rand())))]
    while { $source == $sink } {
        set source [expr int((floor($val(nn) * rand())))]
    }
    # puts "Selected Source $source"
    # Traffic config
    # create agent
    set tcpReno [new Agent/TCP/Reno]
    set tcp_sink [new Agent/TCPSink]
    # attach to nodes
    $ns attach-agent $node($source) $tcpReno
    $ns attach-agent $node($sink) $tcp_sink
    # connect agents
    $ns connect $tcpReno $tcp_sink
    $tcpReno set fid_ $i

    # Traffic generator
    set ftp [new Application/FTP]
    # attach to agent
    $ftp attach-agent $tcpReno
    
    # start traffic generation
    $ns at 1.0 "$ftp start"
}



# End Simulation

# Stop nodes
for {set i 0} {$i < $val(nn)} {incr i} {
    $ns at 50.0 "$node($i) reset"
}

# call final function
proc finish {} {
    global ns trace_file nam_file
    $ns flush-trace
    close $trace_file
    close $nam_file
}

proc halt_simulation {} {
    global ns
    puts "Simulation ending"
    $ns halt
}

$ns at 50.0001 "finish"
$ns at 50.0002 "halt_simulation"

# Run simulation
puts "Simulation starting"
$ns run
