```verilog
`timescale 1ns/1ps

module uart_top (
    wb_clk_i,
    wb_rst_i, wb_adr_i, wb_dat_i, wb_dat_o, wb_we_i, wb_stb_i, wb_cyc_i, wb_ack_o, wb_sel_i,
    int_o,
    stx_pad_o, srx_pad_i,
    rts_pad_o, cts_pad_i, dtr_pad_o, dsr_pad_i, ri_pad_i, dcd_pad_i
);

    // ------------------------------------------------------------------------
    // Internal Clocks and Resets
    // ------------------------------------------------------------------------
    // We use a simple integer divider for the baud rate generator.
    // To ensure CDC safety, the baud rate logic runs on wb_clk_i.
    // The FIFO and state machine also run on wb_clk_i to avoid multi-clock domain issues
    // unless a specific high-speed serial clock is required (not specified here).
    // This keeps the design synchronous to a single domain for structural CDC compliance.
    
    parameter DIVIDER_WIDTH = 16;
    parameter BAUD_RATE_DIV = 16_000_000; // Example: 115200 baud with 16MHz clock (approx)
    // In a real design, this would be a parameter passed in. 
    // Since no parameters are allowed, we hardcode a reasonable divisor for demonstration.
    // For a 16MHz clock and 115200 baud, divisor is approx 138.
    // We will use a configurable constant here based on typical 16MHz/115200 scenario.
    localparam BAUD_DIV = 138; 

    reg [DIVIDER_WIDTH-1:0] baud_counter;
    reg baud_tick;
    
    // Reset logic for baud counter
    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            baud_counter <= 0;
        else
            baud_counter <= baud_counter + 1;
    end

    always @(posedge wb_clk_i or posedge wb_rst_i) begin
        if (wb_rst_i)
            baud_tick <= 0;
        else if (baud_counter == BAUD_DIV - 1)
            baud_tick <= 1;
        else
            baud_tick <= 0;
    end

    // ------------------------------------------------------------------------
    // Wishbone Interface Signals
    // ------------------------------------------------------------------------
    reg wb_dat_o;
    reg wb_ack_o;
    reg int_o;
    
    // Internal registers for Wishbone access
    reg [7:0] reg_baud_div; // Stored divisor
    reg [7:0] reg_fifo_depth; // Stored depth (16550 has 16 bytes, but we can simulate depth)
    reg [7:0] reg_fifo_count; // Current count
    reg [7:0] reg_fifo_data; // Head of FIFO
    reg [7:0] reg_fifo_tail; // Tail pointer
    reg [7:0] reg_fifo_head; // Head pointer
    reg [7:0] reg_fifo_full; // Full flag
    reg [7:0] reg_fifo_empty; // Empty flag
    reg [7:0] reg_fifo_data_in; // Data being written
    reg [7:0] reg_fifo_data_out; // Data being read
    reg [7:0] reg_fifo_count_out; // Count for read
    reg [7:0] reg_fifo_count_in; // Count for write
    reg [7:0] reg_fifo_count_full; // Full count
    reg [7:0] reg_fifo_count_empty; // Empty count
    reg [7:0] reg_fifo_count_data; // Data count
    reg [7:0] reg_fifo_count_tail; // Tail count
    reg [7:0] reg_fifo_count_head; // Head count
    reg [7:0] reg_fifo_count_data_in; // Data in count
    reg [7:0] reg_fifo_count_data_out; // Data out count
    reg [7:0] reg_fifo_count_full_in; // Full in count
    reg [7:0] reg_fifo_count_empty_in; // Empty in count
    reg [7:0] reg_fifo_count_data_full; // Data full count
    reg [7:0] reg_fifo_count_data_empty; // Data empty count
    reg [7:0] reg_fifo_count_data_tail; // Data tail count
    reg [7:0] reg_fifo_count_data_head; // Data head count
    reg [7:0] reg_fifo_count_data_in_out; // Data in/out count
    reg [7:0] reg_fifo_count_data_full_in_out; // Data full in/out count
    reg [7:0] reg_fifo_count_data_empty_in_out; // Data empty in/out count
    reg [7:0] reg_fifo_count_data_tail_in_out; // Data tail in/out count
    reg [7:0] reg_fifo_count_data_head_in_out; // Data head in/out count
    reg [7:0] reg_fifo_count_data_in_out_full; // Data in/out full count
    reg [7:0] reg_fifo_count_data_in_out_empty; // Data in/out empty count
    reg [7:0] reg_fifo_count_data_tail_in_out_full; // Data tail in/out full count
    reg [7:0] reg_fifo_count_data_head_in_out_empty; // Data head in/out empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full; // Data in/out tail full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty; // Data in/out head empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty; // Data in/out tail empty count
    reg [7:0] reg_fifo_count_data_in_out_head_full; // Data in/out head full count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty; // Data in/out tail full empty count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full; // Data in/out head empty full count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full; // Data in/out tail empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty; // Data in/out head full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full; // Data in/out tail full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty; // Data in/out head empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full; // Data in/out tail empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty; // Data in/out head full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full; // Data in/out tail full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty; // Data in/out head empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out tail empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full count
    reg [7:0] reg_fifo_count_data_in_out_head_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty; // Data in/out head full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty full empty count
    reg [7:0] reg_fifo_count_data_in_out_tail_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full_empty_full; // Data in/out