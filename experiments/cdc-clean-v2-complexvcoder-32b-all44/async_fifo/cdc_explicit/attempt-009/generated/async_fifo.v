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

    // Internal signals
    wire [ASIZE-1:0] wptr_gray, rptr_gray;
    wire [ASIZE-1:0] wptr_gray_sync, rptr_gray_sync;
    wire [ASIZE-1:0] wptr_bin, rptr_bin;
    wire [ASIZE-1:0] wptr_gray_sync_bin, rptr_gray_sync_bin;

    // Write pointer gray code counter
    gray_counter wptr_gray_counter (
        .clk(wclk),
        .rst_n(wrst_n),
        .inc(winc & ~wfull),
        .counter_gray(wptr_gray)
    );

    // Read pointer gray code counter
    gray_counter rptr_gray_counter (
        .clk(rclk),
        .rst_n(rrst_n),
        .inc(rinc & ~rempty),
        .counter_gray(rptr_gray)
    );

    // Synchronize write pointer to read domain
    sync_counter wptr_sync (
        .clk_src(wclk),
        .rst_src_n(wrst_n),
        .counter_src(wptr_gray),
        .clk_dst(rclk),
        .counter_dst(wptr_gray_sync)
    );

    // Synchronize read pointer to write domain
    sync_counter rptr_sync (
        .clk_src(rclk),
        .rst_src_n(rrst_n),
        .counter_src(rptr_gray),
        .clk_dst(wclk),
        .counter_dst(rptr_gray_sync)
    );

    // Convert write pointer from gray to binary
    gray_to_bin wptr_bin_converter (
        .counter_gray(wptr_gray),
        .counter_bin(wptr_bin)
    );

    // Convert read pointer from gray to binary
    gray_to_bin rptr_bin_converter (
        .counter_gray(rptr_gray),
        .counter_bin(rptr_bin)
    );

    // Convert synchronized write pointer from gray to binary
    gray_to_bin wptr_gray_sync_bin_converter (
        .counter_gray(wptr_gray_sync),
        .counter_bin(wptr_gray_sync_bin)
    );

    // Convert synchronized read pointer from gray to binary
    gray_to_bin rptr_gray_sync_bin_converter (
        .counter_gray(rptr_gray_sync),
        .counter_bin(rptr_gray_sync_bin)
    );

    // FIFO memory module
    fifo_memory fifo_mem (
        .wclk(wclk),
        .wrst_n(wrst_n),
        .wptr_bin(wptr_bin),
        .winc(winc & ~wfull),
        .wdata(wdata),
        .rclk(rclk),
        .rptr_bin(rptr_bin),
        .rinc(rinc & ~rempty),
        .rdata(rdata),
        .wfull(wfull),
        .awfull(awfull),
        .rempty(rempty),
        .arempty(arempty)
    );

endmodule

module sync_counter (
    input  wire             clk_src,
    input  wire             rst_src_n,
    input  wire [ASIZE-1:0] counter_src,
    input  wire             clk_dst,
    output wire [ASIZE-1:0] counter_dst
);

    reg [ASIZE-1:0] counter_sync_stage1;
    reg [ASIZE-1:0] counter_sync_stage2;

    always @(posedge clk_dst or negedge rst_src_n) begin
        if (!rst_src_n) begin
            counter_sync_stage1 <= 0;
            counter_sync_stage2 <= 0;
        end else begin
            counter_sync_stage1 <= counter_src;
            counter_sync_stage2 <= counter_sync_stage1;
        end
    end

    assign counter_dst = counter_sync_stage2;

endmodule

module gray_counter (
    input  wire             clk,
    input  wire             rst_n,
    input  wire             inc,
    output wire [ASIZE-1:0] counter_gray
);

    reg [ASIZE-1:0] counter_bin;
    reg [ASIZE-1:0] counter_gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_bin <= 0;
            counter_gray_reg <= 0;
        end else if (inc) begin
            counter_bin <= counter_bin + 1;
            counter_gray_reg <= (counter_bin + 1) ^ (counter_bin + 1 >> 1);
        end
    end

    assign counter_gray = counter_gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] counter_gray,
    output wire [ASIZE-1:0] counter_bin
);

    wire [ASIZE-1:0] counter_bin_internal;

    assign counter_bin_internal[0] = counter_gray[0];
    generate
        genvar i;
        for (i = 1; i < ASIZE; i = i + 1) begin : gray_to_bin_loop
            assign counter_bin_internal[i] = counter_bin_internal[i-1] ^ counter_gray[i];
        end
    endgenerate

    assign counter_bin = counter_bin_internal;

endmodule

module fifo_memory
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire             wclk,
        input  wire             wrst_n,
        input  wire [ASIZE-1:0] wptr_bin,
        input  wire             winc,
        input  wire [DSIZE-1:0] wdata,
        input  wire             rclk,
        input  wire [ASIZE-1:0] rptr_bin,
        input  wire             rinc,
        output wire [DSIZE-1:0] rdata,
        output wire             wfull,
        output wire             awfull,
        output wire             rempty,
        output wire             arempty
    );

    reg [DSIZE-1:0] memory [0:(2**ASIZE)-1];
    reg [ASIZE:0] wptr_bin_gray;
    reg [ASIZE:0] rptr_bin_gray;
    reg [ASIZE:0] wptr_bin_next;
    reg [ASIZE:0] rptr_bin_next;

    // Write pointer in gray code
    assign wptr_bin_gray = (wptr_bin + 1) ^ (wptr_bin + 1 >> 1);

    // Read pointer in gray code
    assign rptr_bin_gray = rptr_bin ^ (rptr_bin >> 1);

    // Next write pointer
    assign wptr_bin_next = wptr_bin + 1;

    // Next read pointer
    assign rptr_bin_next = rptr_bin + 1;

    // Write data to memory
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            memory[0] <= 0;
        end else if (winc & ~wfull) begin
            memory[wptr_bin] <= wdata;
        end
    end

    // Read data from memory
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            memory[0] <= 0;
        end
    end

    assign rdata = memory[rptr_bin];

    // FIFO full condition
    assign wfull = (wptr_bin_gray == {rptr_bin_gray[ASIZE-1:0], ~rptr_bin_gray[ASIZE-1]});

    // FIFO almost full condition
    assign awfull = (wptr_bin_gray == {rptr_bin_gray[ASIZE-2:0], ~rptr_bin_gray[ASIZE-2], ~rptr_bin_gray[ASIZE-1]});

    // FIFO empty condition
    assign rempty = (wptr_bin_gray[ASIZE-1:0] == rptr_bin_gray);

    // FIFO almost empty condition
    assign arempty = (wptr_bin_gray[ASIZE-2:0] == rptr_bin_gray[ASIZE-2:0]) & (wptr_bin_gray[ASIZE-1] != rptr_bin_gray[ASIZE-1]);

endmodule
