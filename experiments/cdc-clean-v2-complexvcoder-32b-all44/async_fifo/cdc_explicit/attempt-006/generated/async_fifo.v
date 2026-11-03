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
    wire [ASIZE:0] w_gray, r_gray, r_w_gray, w_r_gray;
    wire [ASIZE:0] w_bin, r_bin, r_w_bin, w_r_bin;

    // Write domain
    gray_counter write_counter (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .w_gray (w_gray)
    );

    gray_to_bin write_gray_to_bin (
        .w_gray (w_gray),
        .w_bin  (w_bin)
    );

    sync_gray write_sync_gray (
        .w_gray (w_gray),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .r_w_gray (r_w_gray)
    );

    gray_to_bin synced_write_gray_to_bin (
        .r_w_gray (r_w_gray),
        .r_w_bin  (r_w_bin)
    );

    // Read domain
    gray_counter read_counter (
        .wclk   (rclk),
        .wrst_n (rrst_n),
        .winc   (rinc),
        .w_gray (r_gray)
    );

    gray_to_bin read_gray_to_bin (
        .w_gray (r_gray),
        .w_bin  (r_bin)
    );

    sync_gray read_sync_gray (
        .w_gray (r_gray),
        .rclk   (wclk),
        .rrst_n (wrst_n),
        .r_w_gray (w_r_gray)
    );

    gray_to_bin synced_read_gray_to_bin (
        .r_w_gray (w_r_gray),
        .r_w_bin  (w_r_bin)
    );

    // FIFO memory
    dual_clock_ram fifo_memory (
        .wclk   (wclk),
        .wrst_n (wrst_n),
        .winc   (winc),
        .wdata  (wdata),
        .w_bin  (w_bin),
        .rclk   (rclk),
        .rrst_n (rrst_n),
        .r_bin  (r_bin),
        .rdata  (rdata)
    );

    // FIFO control signals
    wire [ASIZE:0] w_ptr, r_ptr, r_w_ptr, w_r_ptr;
    wire [ASIZE:0] w_full_threshold, w_almost_full_threshold;
    wire [ASIZE:0] r_empty_threshold, r_almost_empty_threshold;

    assign w_ptr = w_bin;
    assign r_ptr = r_bin;
    assign r_w_ptr = r_w_bin;
    assign w_r_ptr = w_r_bin;

    assign w_full_threshold = {1'b0, {(ASIZE-1){1'b1}}, 1'b0}; // 2**ASIZE - 1
    assign w_almost_full_threshold = {1'b0, {(ASIZE-1){1'b1}}, 1'b1}; // 2**ASIZE - 2
    assign r_empty_threshold = 0;
    assign r_almost_empty_threshold = 1;

    assign wfull = (r_w_ptr == {w_ptr[ASIZE], w_ptr[ASIZE-1:0] + 1'b1});
    assign awfull = (r_w_ptr == {w_ptr[ASIZE], w_ptr[ASIZE-1:0] + w_almost_full_threshold});
    assign rempty = (w_r_ptr == r_ptr);
    assign arempty = (w_r_ptr == {r_ptr[ASIZE], r_ptr[ASIZE-1:0] + r_almost_empty_threshold});

endmodule

// Gray counter module
module gray_counter (
    input  wire clk,
    input  wire rst_n,
    input  wire inc,
    output wire [ASIZE:0] w_gray
);

    reg [ASIZE:0] gray_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            gray_reg <= 0;
        else if (inc)
            gray_reg <= gray_reg + 1;
    end

    assign w_gray = (gray_reg ^ (gray_reg >> 1));

endmodule

// Gray to binary converter module
module gray_to_bin (
    input  wire [ASIZE:0] w_gray,
    output wire [ASIZE:0] w_bin
);

    assign w_bin = w_gray ^ (w_gray >> 1) ^ (w_gray >> 2) ^ (w_gray >> 3) ^ (w_gray >> 4);

endmodule

// Synchronizer for gray counter module
module sync_gray (
    input  wire [ASIZE:0] w_gray,
    input  wire clk,
    input  wire rst_n,
    output reg [ASIZE:0] r_w_gray
);

    reg [ASIZE:0] sync_stage1, sync_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= 0;
            sync_stage2 <= 0;
            r_w_gray <= 0;
        end else begin
            sync_stage1 <= w_gray;
            sync_stage2 <= sync_stage1;
            r_w_gray <= sync_stage2;
        end
    end

endmodule

// Dual clock RAM module
module dual_clock_ram (
    input  wire wclk,
    input  wire wrst_n,
    input  wire winc,
    input  wire [DSIZE-1:0] wdata,
    input  wire [ASIZE:0] w_bin,
    input  wire rclk,
    input  wire rrst_n,
    input  wire [ASIZE:0] r_bin,
    output reg [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] mem [0:(2**ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: 0};
        end else if (winc) begin
            mem[w_bin[ASIZE-1:0]] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata <= 0;
        else
            rdata <= mem[r_bin[ASIZE-1:0]];
    end

endmodule
