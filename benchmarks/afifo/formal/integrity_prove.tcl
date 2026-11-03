# End-to-end data integrity for frozen afifo.
# Scope: the DUT defaults elaborated here. LGFIFO=3 (depth 8),
# WIDTH=16, NFF=2, WRITE_ON_POSEDGE=1, OPT_REGISTER_READS=1.
# Harness counts are 4 bits and pointer lemmas compare 3 bits.
# This is not a proof for other parameter values.
#
# The generated mux check is recorded and is not an injection target.
# Reset implications are audited for antecedent reachability. They are
# not part of the safety claim. The claim is the post-initialization
# region in which both resets stay released.

set TOP      afifo_integrity_top
set BENCH_DIR $env(DS)/benchmarks/afifo
set SDC_FILE $BENCH_DIR/constraints/afifo.sdc
set RPT_DIR  $env(DS)/build/jasper/afifo_v2_integrity

file mkdir $RPT_DIR
clear -all
analyze -v2k $BENCH_DIR/fixed/rtl/afifo.v
analyze -sv $BENCH_DIR/formal/afifo_integrity.v
elaborate -bbox_a 50000 -top $TOP

read_sdc $SDC_FILE
check_cdc -init
clock i_wclk
clock i_rclk
config_rtlds -reset -async i_wr_reset_n -polarity low
config_rtlds -reset -async i_rd_reset_n -polarity low
config_rtlds -port \
    {i_wr_reset_n i_wr i_wr_data i_pick o_wr_full} \
    -clock i_wclk
config_rtlds -port \
    {i_rd_reset_n i_rd o_rd_data o_rd_empty} \
    -clock i_rclk
config_rtlds -clock -group -async {{i_wclk} {i_rclk}}
reset {~i_wr_reset_n ~i_rd_reset_n}

check_cdc -extract
check_cdc -list pairs -file $RPT_DIR/cdc_pairs.rpt -force
check_cdc -list domain_crossings -file $RPT_DIR/cdc_crossings.rpt -force
check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report_structural.rpt -force

proc integrity_fail {msg} {
    puts "\[integrity\] FAIL $msg"
    exit 1
}

proc integrity_field {name field} {
    set raw [get_property_info -list $field $name]
    return [string trim $raw]
}

proc integrity_report {name} {
    set validity [integrity_field $name validity_status]
    set run [integrity_field $name run_status]
    set engine [integrity_field $name engine]
    set tm [integrity_field $name time]
    puts "\[integrity\] status $name validity=$validity run=$run engine=$engine time=$tm"
    return $validity
}

proc integrity_require_proven {names} {
    foreach name $names {
        if {[catch {set validity [integrity_report $name]} err]} {
            integrity_fail "cannot read $name ($err)"
        }
        set run [integrity_field $name run_status]
        if {$validity ne "proven" || $run ne "processed"} {
            integrity_fail "$name validity=$validity run=$run; not converting it to an assumption"
        }
    }
}

proc integrity_require_covered {names} {
    foreach name $names {
        if {[catch {set validity [integrity_report $name]} err]} {
            integrity_fail "cannot read $name ($err)"
        }
        set run [integrity_field $name run_status]
        if {$validity ne "covered" || $run ne "processed"} {
            integrity_fail "$name validity=$validity run=$run"
        }
    }
}

puts "\[integrity\] builtin_memory_check_begin"
set generated [check_cdc -protocol_check -generate]
puts "\[integrity\] builtin_generated $generated"
set builtin [check_cdc -protocol_check -prove -property {CDC_dut.data_q_datapath_stable}]
puts "\[integrity\] builtin_memory_check $builtin"

set helpers { \
    afifo_integrity_top.outstanding_le_w \
    afifo_integrity_top.outstanding_le_r \
    afifo_integrity_top.wr_ptr_tracks \
    afifo_integrity_top.rd_ptr_tracks \
    afifo_integrity_top.mem_matches \
    afifo_integrity_top.mem_matches_r \
}
set lemmas [concat $helpers { \
    afifo_integrity_top.chk.no_underflow \
    afifo_integrity_top.chk.within_capacity \
}]
set covers { \
    afifo_integrity_top.chk.fill8 \
    afifo_integrity_top.chk.drain8 \
}
set support [concat $lemmas $covers]
set target afifo_integrity_top.chk.oldest_unread
set tested afifo_integrity_top.tested_cfg
set reset_asserts { \
    afifo_integrity_top.chk.full_low_in_write_reset \
    afifo_integrity_top.chk.empty_high_in_read_reset \
}
set reset_antecedents { \
    afifo_integrity_top.chk.wr_reset_antecedent \
    afifo_integrity_top.chk.rd_reset_antecedent \
}

foreach name [concat $helpers $support [list $target $tested] $reset_asserts $reset_antecedents] {
    if {[catch {integrity_field $name name} err]} {
        integrity_fail "missing property $name ($err)"
    }
    puts "\[integrity\] property_present $name"
}

foreach h $helpers {
    assert -set_helper $h
}

# Antecedent covers and reset implications, before resets are assumed
# to stay released. A proven implication whose antecedent cover is
# unreachable is not evidence of in-reset behavior.
set_prove_time_limit 60s
puts "\[integrity\] reset_antecedent_begin"
set antecedent_result [prove -property $reset_antecedents]
puts "\[integrity\] reset_antecedent_result $antecedent_result"
set reset_antecedent_reachable 1
foreach name $reset_antecedents {
    set validity [integrity_report $name]
    if {$validity ne "covered"} {
        set reset_antecedent_reachable 0
    }
}

puts "\[integrity\] reset_checks_begin"
set reset_proved [prove -property $reset_asserts]
puts "\[integrity\] reset_checks_result $reset_proved"
set reset_evidence 1
foreach name $reset_asserts {
    set validity [integrity_report $name]
    if {$validity ne "proven"} {
        set reset_evidence 0
    }
    set related [get_property_info -list related_covers $name]
    puts "\[integrity\] reset_related_list $name $related"
    if {[llength $related] == 0} {
        set reset_evidence 0
        continue
    }
    set related_result [prove -property $related]
    puts "\[integrity\] reset_related_result $name $related_result"
    foreach cover_name $related {
        set cover_status [integrity_report $cover_name]
        if {$cover_status ne "covered"} {
            set reset_evidence 0
        }
    }
}
if {$reset_evidence && $reset_antecedent_reachable} {
    puts "\[integrity\] reset_checks antecedent covered and implication proven"
} else {
    puts "\[integrity\] reset_checks are not evidence of in-reset behavior"
    puts "\[integrity\] operating region is after initialization with resets held released"
}

assume -name hold_wr_reset {@(posedge i_wclk) i_wr_reset_n}
assume -name hold_rd_reset {@(posedge i_rclk) i_rd_reset_n}

set_prove_time_limit 120s
puts "\[integrity\] helpers_begin"
set helped [prove -property [concat [list $tested] $support] -with_helpers]
puts "\[integrity\] helpers $helped"
integrity_require_proven [concat [list $tested] $lemmas]
integrity_require_covered $covers

set_prove_time_limit 180s
puts "\[integrity\] prove_begin"
set proved [prove -property $target -with_helpers -with_proven]
puts "\[integrity\] prove $proved"
integrity_require_proven [list $target]

puts "\[integrity\] metastability_inject"
set injected [check_cdc -metastability -inject -include_reset]
puts "\[integrity\] injected $injected"
set saw_req 0
set saw_ack 0
if {[llength $injected] != 2} {
    integrity_fail "injection set is not the two req/ack pairs: $injected"
}
foreach pair $injected {
    if {[string match *dut.req-dut.req_sync* $pair]} {
        set saw_req 1
    } elseif {[string match *dut.ack-dut.ack_sync* $pair]} {
        set saw_ack 1
    } else {
        integrity_fail "unexpected injection pair $pair"
    }
}
if {!$saw_req || !$saw_ack} {
    integrity_fail "req/ack injection pair missing: $injected"
}

puts "\[integrity\] metastability_helpers_begin"
set mhelp [check_cdc -metastability -prove -property $support]
puts "\[integrity\] metastability_helpers $mhelp"
integrity_require_proven $lemmas
integrity_require_covered $covers

# Metastability prove does not take -with_helpers. Convert only the
# lemmas whose injected proof status was just confirmed above.
foreach h $lemmas {
    assume -from_assert $h
}

set_prove_time_limit 120s
puts "\[integrity\] metastability_prove_begin"
set mproved [check_cdc -metastability -prove -property $target]
puts "\[integrity\] metastability_prove $mproved"
integrity_require_proven [list $target]

check_cdc -report -violation -detailed -file $RPT_DIR/cdc_report_after_msi.rpt -force
puts "\[integrity\] claim For the tested configuration (depth 8, width 16, NFF 2, registered reads, write on posedge), after initialization and with resets held released, accepted reads return the corresponding written data in order, with capacity and underflow properties proven under request/acknowledge metastability injection."
puts "\[integrity\] claim_limits safety only; fill8 and drain8 show traffic is possible and do not prove that every pending word is eventually delivered; CDC_dut.data_q_datapath_stable remains a separate failure"
puts "\[integrity\] done"
