#############################################################################
# Reusable JasperGold CDC driver + SDC-completeness check.
#
# Purpose:
#   1. Elaborate a CDC design.
#   2. Load the design's SDC (the DECLARED clocks/resets).
#   3. Let JasperGold AUTO-INFER clocks/resets from the netlist.
#   4. Dump both so you can diff INFERRED vs DECLARED -> that diff is the
#      SDC-completeness verdict (any inferred clock/reset not in the SDC = gap).
#   5. Run the actual CDC structural analysis and dump the report.
#
# Usage (from a per-design wrapper in ../<design>.tcl):
#     set TOP        async_fifo
#     set RTL_FILES  [glob $env(DS)/dpretet_async_fifo/rtl/*.v]
#     set SDC_FILE   $env(DS)/dpretet_async_fifo/sdc/async_fifo.sdc
#     set HDL_STD    -v2k        ;# -v2k | -sv09 | -sv12
#     source $env(DS)/jg/lib/cdc_run.tcl
#     cdc_run $TOP $RTL_FILES $SDC_FILE $HDL_STD
#
# IMPORTANT - VERSION NOTE:
#   The JasperGold CDC app "check_cdc" subcommand names have varied across
#   releases. Lines tagged  ;##CONFIRM##  should be checked once against your
#   installed version with:  help check_cdc   (then they are stable for you).
#   Everything NOT tagged (clear/analyze/elaborate/read_sdc/report) is standard.
#############################################################################

proc cdc_run {top rtl_files sdc_file {hdl_std -v2k}} {
    set rptdir "cdc_reports/$top"
    file mkdir $rptdir

    # ---------------------------------------------------------------
    # 1. Read + elaborate
    # ---------------------------------------------------------------
    clear -all
    analyze $hdl_std {*}$rtl_files
    elaborate -top $top

    # ---------------------------------------------------------------
    # 2. DECLARED constraints: import create_clock / set_clock_groups
    #    (JasperGold reads standard SDC clock constraints)
    # ---------------------------------------------------------------
    read_sdc $sdc_file

    # ---------------------------------------------------------------
    # 3. INFERRED clocks/resets: ask the tool to auto-detect, then dump.
    #    The completeness check is: compare this against the SDC above.
    # ---------------------------------------------------------------
    check_cdc -init                                       ;##CONFIRM##
    check_cdc -clock -detect -report $rptdir/inferred_clocks.rpt   ;##CONFIRM##
    check_cdc -reset -detect -report $rptdir/inferred_resets.rpt   ;##CONFIRM##

    # ---------------------------------------------------------------
    # 4. Run the CDC structural analysis + dump results
    # ---------------------------------------------------------------
    check_cdc -generate_scheme                            ;##CONFIRM##
    check_cdc -analyze                                    ;##CONFIRM##
    check_cdc -report -file $rptdir/cdc_crossings.rpt     ;##CONFIRM##

    # ---------------------------------------------------------------
    # 5. Completeness summary hint
    # ---------------------------------------------------------------
    puts "======================================================================"
    puts "\[cdc_run\] $top: done."
    puts "  Declared (SDC)  : $sdc_file"
    puts "  Inferred clocks : $rptdir/inferred_clocks.rpt"
    puts "  Inferred resets : $rptdir/inferred_resets.rpt"
    puts "  CDC crossings   : $rptdir/cdc_crossings.rpt"
    puts ""
    puts "  SDC IS COMPLETE  iff every clock/reset in the 'inferred' reports is"
    puts "  also declared in the SDC, AND JasperGold reports 0 unconstrained /"
    puts "  0 undefined-clock flops. Any inferred-but-not-declared item = a gap"
    puts "  (add a create_clock / reset declaration and re-run)."
    puts "======================================================================"
}
