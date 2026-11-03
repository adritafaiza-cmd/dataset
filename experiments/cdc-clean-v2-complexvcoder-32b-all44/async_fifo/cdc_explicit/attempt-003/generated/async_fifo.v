module async_fifo
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4,
        parameter FALLTHROUGH = "TRUE"
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        output wire             wfull,
        output wire             awfull,
        input  wire             rclk,
        input  wire             rrst_n,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             rempty,
        output wire             arempty
    );

    localparam DEPTH = 2**ASIZE;
    localparam ALMOST_FULL_THRESHOLD = DEPTH - 2;
    localparam ALMOST_EMPTY_THRESHOLD = 1;

    reg [DSIZE-1:0] mem [0:DEPTH-1];
    reg [ASIZE-1:0] wptr, rptr;
    reg [ASIZE-1:0] wptr_gray, rptr_gray;
    reg [ASIZE-1:0] wptr_bin, rptr_bin;
    reg [DSIZE-1:0] mem_out, rdata_stage1, rdata_stage2;
    reg wfull_flag, rempty_flag, awfull_flag, arempty_flag;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wfull_flag <= 0;
            awfull_flag <= 0;
        end else begin
            if (winc && !wfull_flag) begin
                mem[wptr_bin] <= wdata;
                wptr <= wptr + 1;
            end
            wptr_gray <= (wptr >> 1) ^ wptr;
            wfull_flag <= (wptr_gray == {~rptr_gray[ASIZE-1:1], rptr_gray[ASIZE-2:0]});
            awfull_flag <= (wptr_gray == {~rptr_gray[ASIZE-1:1], rptr_gray[ASIZE-2:0] + 1});
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rempty_flag <= 1;
            arempty_flag <= 1;
        end else begin
            if (rinc && !rempty_flag) begin
                rptr <= rptr + 1;
            end
            rptr_gray <= (rptr >> 1) ^ rptr;
            rempty_flag <= (rptr_gray == wptr_gray);
            arempty_flag <= (rptr_gray == {~wptr_gray[ASIZE-1:1], wptr_gray[ASIZE-2:0]});
        end
    end

    // Gray to binary conversion for write pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            wptr_bin <= 0;
        else
            wptr_bin <= gray_to_bin(wptr_gray);
    end

    // Gray to binary conversion for read pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            rptr_bin <= 0;
        else
            rptr_bin <= gray_to_bin(rptr_gray);
    end

    // Memory read
    always @(posedge rclk) begin
        mem_out <= mem[rptr_bin];
    end

    // Data pipeline stages
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_stage1 <= 0;
            rdata_stage2 <= 0;
        end else begin
            rdata_stage1 <= mem_out;
            rdata_stage2 <= rdata_stage1;
        end
    end

    // Output assignments
    assign wfull = wfull_flag;
    assign awfull = awfull_flag;
    assign rempty = rempty_flag;
    assign arempty = arempty_flag;
    assign rdata = FALLTHROUGH ? (rempty_flag ? rdata_stage2 : mem_out) : rdata_stage2;

    // Gray to binary conversion function
    function [ASIZE-1:0] gray_to_bin;
        input [ASIZE-1:0] gray;
        integer i;
        begin
            gray_to_bin[0] = gray[0];
            for (i = 1; i < ASIZE; i = i + 1) begin
                gray_to_bin[i] = gray_to_bin[i-1] ^ gray[i];
            end
        end
    endfunction

    // Synchronization counters
    sync_counter wptr_sync (
        .src_clk(wclk),
        .src_rst_n(wrst_n),
        .counter_in(wptr_gray),
        .dst_clk(rclk),
        .counter_out(rptr_gray)
    );

    sync_counter rptr_sync (
        .src_clk(rclk),
        .src_rst_n(rrst_n),
        .counter_in(rptr_gray),
        .dst_clk(wclk),
        .counter_out(wptr_gray)
    );

endmodule

module sync_counter (
    input  wire src_clk,
    input  wire src_rst_n,
    input  wire [ASIZE-1:0] counter_in,
    input  wire dst_clk,
    output reg [ASIZE-1:0] counter_out
);

    reg [ASIZE-1:0] sync_reg1, sync_reg2;

    always @(posedge src_clk or negedge src_rst_n) begin
        if (!src_rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= counter_in;
            sync_reg2 <= sync_reg1;
        end
    end

    always @(posedge dst_clk or negedge src_rst_n) begin
        if (!src_rst_n)
            counter_out <= 0;
        else
            counter_out <= sync_reg2;
    end

endmodule
