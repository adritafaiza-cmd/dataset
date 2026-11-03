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
    wire [ASIZE-1:0] gray_wptr_count, wptr_bin;
    wire [ASIZE-1:0] gray_rptr_count, rptr_bin;
    wire [ASIZE-1:0] gray_wptr_sync_rclk;
    wire [ASIZE-1:0] gray_rptr_sync_wclk;
    wire wfull_raw, awfull_raw;
    wire rempty_raw, arempty_raw;

    // Gray code counters
    gray_counter #(.ASIZE(ASIZE))
    gray_wptr (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc & ~wfull),
        .count (gray_wptr_count),
        .bin   (wptr_bin)
    );

    gray_counter #(.ASIZE(ASIZE))
    gray_rptr (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc & ~rempty),
        .count (gray_rptr_count),
        .bin   (rptr_bin)
    );

    // Synchronizers
    sync_register #(.ASIZE(ASIZE))
    wptr_sync_to_rclk (
        .clk   (rclk),
        .rst_n (rrst_n),
        .din   (gray_wptr_count),
        .dout  (gray_wptr_sync_rclk)
    );

    sync_register #(.ASIZE(ASIZE))
    rptr_sync_to_wclk (
        .clk   (wclk),
        .rst_n (wrst_n),
        .din   (gray_rptr_count),
        .dout  (gray_rptr_sync_wclk)
    );

    // Memory array
    memory_array #(.DSIZE(DSIZE), .ASIZE(ASIZE))
    fifo_memory (
        .clk   (wclk),
        .wrst_n(wrst_n),
        .wen   (winc & ~wfull),
        .waddr (wptr_bin),
        .wdata (wdata),
        .raddr (rptr_bin),
        .rdata (rdata)
    );

    // Full and almost full detection
    assign wfull_raw = (gray_wptr_count == gray_rptr_sync_wclk + {ASIZE{1'b1}});
    assign awfull_raw = (gray_wptr_count == gray_rptr_sync_wclk + {ASIZE-1{1'b1}, 1'b0});

    // Empty and almost empty detection
    assign rempty_raw = (gray_wptr_sync_rclk == gray_rptr_count);
    assign arempty_raw = (gray_wptr_sync_rclk == gray_rptr_count + {ASIZE-1{1'b0}, 1'b1});

    // Outputs
    assign wfull  = wfull_raw;
    assign awfull = awfull_raw;
    assign rempty = rempty_raw;
    assign arempty = arempty_raw;

endmodule

module gray_counter
    #(
        parameter ASIZE = 4
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire             inc,
        output wire [ASIZE-1:0] count,
        output wire [ASIZE-1:0] bin
    );

    reg [ASIZE-1:0] bin_reg;
    reg [ASIZE-1:0] count_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_reg   <= {ASIZE{1'b0}};
            count_reg <= {ASIZE{1'b0}};
        end else if (inc) begin
            bin_reg   <= bin_reg + 1;
            count_reg <= (bin_reg + 1) ^ (bin_reg + 1) >> 1;
        end
    end

    assign bin   = bin_reg;
    assign count = count_reg;

endmodule

module sync_register
    #(
        parameter ASIZE = 4
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire [ASIZE-1:0] din,
        output wire [ASIZE-1:0] dout
    );

    reg [ASIZE-1:0] sync_reg1;
    reg [ASIZE-1:0] sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= {ASIZE{1'b0}};
            sync_reg2 <= {ASIZE{1'b0}};
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule

module memory_array
    #(
        parameter DSIZE = 8,
        parameter ASIZE = 4
    )(
        input  wire             clk,
        input  wire             wrst_n,
        input  wire             wen,
        input  wire [ASIZE-1:0] waddr,
        input  wire [DSIZE-1:0] wdata,
        input  wire [ASIZE-1:0] raddr,
        output wire [DSIZE-1:0] rdata
    );

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

    always @(posedge clk or negedge wrst_n) begin
        if (!wrst_n) begin
            for (integer i = 0; i < (1<<ASIZE); i = i + 1) begin
                mem[i] <= {DSIZE{1'b0}};
            end
        end else if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    assign rdata = mem[raddr];

endmodule
