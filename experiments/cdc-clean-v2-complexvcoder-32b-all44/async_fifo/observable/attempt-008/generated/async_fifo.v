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

    wire [ASIZE-1:0] gray_w, gray_r, gray_w_sync, gray_r_sync;
    wire [ASIZE-1:0] bin_w, bin_r, bin_w_sync, bin_r_sync;
    wire full_raw, empty_raw;

    // Gray counters for write and read pointers
    gray_counter gray_counter_w (
        .clk   (wclk),
        .rst_n (wrst_n),
        .inc   (winc & ~wfull),
        .gray  (gray_w)
    );

    gray_counter gray_counter_r (
        .clk   (rclk),
        .rst_n (rrst_n),
        .inc   (rinc & ~rempty),
        .gray  (gray_r)
    );

    // Convert Gray codes to Binary
    gray_to_bin gray_to_bin_w (
        .gray (gray_w),
        .bin  (bin_w)
    );

    gray_to_bin gray_to_bin_r (
        .gray (gray_r),
        .bin  (bin_r)
    );

    // Synchronize read pointer to write clock domain
    sync_register sync_register_gray_r (
        .din   (gray_r),
        .clk   (wclk),
        .rst_n (wrst_n),
        .dout  (gray_r_sync)
    );

    // Synchronize write pointer to read clock domain
    sync_register sync_register_gray_w (
        .din   (gray_w),
        .clk   (rclk),
        .rst_n (rrst_n),
        .dout  (gray_w_sync)
    );

    // Convert synchronized Gray codes to Binary
    gray_to_bin gray_to_bin_r_sync (
        .gray (gray_r_sync),
        .bin  (bin_r_sync)
    );

    gray_to_bin gray_to_bin_w_sync (
        .gray (gray_w_sync),
        .bin  (bin_w_sync)
    );

    // FIFO memory
    fifo_memory fifo_memory_inst (
        .clk    (wclk),
        .rst_n  (wrst_n),
        .winc   (winc & ~wfull),
        .waddr  (bin_w),
        .din    (wdata),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .rinc   (rinc & ~rempty),
        .raddr  (bin_r),
        .dout   (rdata)
    );

    // Full and empty detection
    assign full_raw  = (bin_w_sync == {bin_r_sync[ASIZE-2:0], ~bin_r_sync[ASIZE-1]});
    assign empty_raw = (bin_w_sync == bin_r_sync);

    // Flags
    assign wfull  = full_raw;
    assign awfull = (bin_w_sync == {bin_r_sync[ASIZE-2:0], ~bin_r_sync[ASIZE-1]});
    assign rempty = empty_raw;
    assign arempty = (bin_w_sync == bin_r_sync);

endmodule

module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output reg [ASIZE-1:0] gray
);

    reg [ASIZE-1:0] gray_reg, gray_next;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_reg <= 0;
        end else if (inc) begin
            gray_reg <= gray_next;
        end
    end

    assign gray_next = gray_reg + 1;
    assign gray = gray_reg;

endmodule

module gray_to_bin (
    input  wire [ASIZE-1:0] gray,
    output wire [ASIZE-1:0] bin
);

    wire [ASIZE-1:0] gray_shift;

    generate
        genvar i;
        for (i = 0; i < ASIZE; i = i + 1) begin : gray_to_bin_gen
            assign gray_shift[i] = gray[ASIZE-1] ^ gray[ASIZE-1-i];
        end
    endgenerate

    assign bin = gray_shift ^ {ASIZE{1'b0}};

endmodule

module sync_register (
    input  wire [ASIZE-1:0] din,
    input  wire clk,
    input  wire rst_n,
    output reg [ASIZE-1:0] dout
);

    reg [ASIZE-1:0] sync_reg1, sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule

module fifo_memory (
    input  wire clk,
    input  wire rst_n,
    input  wire winc,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] din,
    input  wire rclk,
    input  wire rrst_n,
    input  wire rinc,
    input  wire [ASIZE-1:0] raddr,
    output reg [DSIZE-1:0] dout
);

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 0;
            mem  <= '{default: 0};
        end else if (winc) begin
            mem[waddr] <= din;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            dout <= 0;
        end else if (rinc) begin
            dout <= mem[raddr];
        end
    end

endmodule
