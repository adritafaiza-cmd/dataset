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
    wire [ASIZE:0] gray_wptr_out;
    wire [ASIZE:0] gray_rptr_out;
    wire [ASIZE:0] sync_gray_wptr_out;
    wire [ASIZE:0] sync_gray_rptr_out;
    wire [ASIZE-1:0] wptr_bin;
    wire [ASIZE-1:0] rptr_bin;
    wire [ASIZE:1] wptr_gray;
    wire [ASIZE:1] rptr_gray;
    wire [ASIZE:1] sync_wptr_gray;
    wire [ASIZE:1] sync_rptr_gray;
    wire [ASIZE:0] wptr_plus_1;
    wire [ASIZE:0] rptr_plus_1;
    wire [ASIZE:0] wptr_plus_2;
    wire [ASIZE:0] rptr_plus_2;

    // Write domain logic
    gray_counter u_gray_wptr (
        .clk       (wclk),
        .rst_n     (wrst_n),
        .inc       (winc),
        .gray_count(gray_wptr_out)
    );

    sync_gray_counter u_sync_gray_wptr (
        .clk           (rclk),
        .rst_n         (rrst_n),
        .gray_count    (gray_wptr_out),
        .sync_gray_count(sync_gray_wptr_out)
    );

    // Read domain logic
    gray_counter u_gray_rptr (
        .clk       (rclk),
        .rst_n     (rrst_n),
        .inc       (rinc),
        .gray_count(gray_rptr_out)
    );

    sync_gray_counter u_sync_gray_rptr (
        .clk           (wclk),
        .rst_n         (wrst_n),
        .gray_count    (gray_rptr_out),
        .sync_gray_count(sync_gray_rptr_out)
    );

    // Memory array
    memory_array u_fifo_memory (
        .wclk     (wclk),
        .wrst_n   (wrst_n),
        .waddr    (sync_gray_rptr_out[ASIZE:1]),
        .wdata    (wdata),
        .wen      (winc),
        .rclk     (rclk),
        .rrst_n   (rrst_n),
        .raddr    (sync_gray_wptr_out[ASIZE:1]),
        .rdata    (rdata)
    );

    // Binary conversion and pointer arithmetic
    binary_gray #(.WIDTH(ASIZE+1)) u_bin_gray_wptr (
        .gray_in  (gray_wptr_out),
        .bin_out  (wptr_bin)
    );

    binary_gray #(.WIDTH(ASIZE+1)) u_bin_gray_rptr (
        .gray_in  (gray_rptr_out),
        .bin_out  (rptr_bin)
    );

    binary_gray #(.WIDTH(ASIZE+1)) u_bin_gray_sync_wptr (
        .gray_in  (sync_gray_wptr_out),
        .bin_out  (/* not used */)
    );

    binary_gray #(.WIDTH(ASIZE+1)) u_bin_gray_sync_rptr (
        .gray_in  (sync_gray_rptr_out),
        .bin_out  (/* not used */)
    );

    assign wptr_plus_1 = wptr_bin + 1;
    assign wptr_plus_2 = wptr_bin + 2;
    assign rptr_plus_1 = rptr_bin + 1;
    assign rptr_plus_2 = rptr_bin + 2;

    // Full and empty flags
    assign wfull = (wptr_plus_1 == sync_gray_rptr_out[ASIZE:1]);
    assign awfull = (wptr_plus_2 == sync_gray_rptr_out[ASIZE:1]);
    assign rempty = (wptr_bin == sync_gray_rptr_out[ASIZE:1]);
    assign arempty = (rptr_plus_1 == sync_gray_wptr_out[ASIZE:1]);

    // First-word fall-through
    reg [DSIZE-1:0] fallthrough_data;
    reg fallthrough_valid;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            fallthrough_data <= {DSIZE{1'b0}};
            fallthrough_valid <= 1'b0;
        end else begin
            if (!rempty && rinc) begin
                fallthrough_data <= rdata;
                fallthrough_valid <= 1'b1;
            end else if (rinc) begin
                fallthrough_valid <= 1'b0;
            end
        end
    end

    assign rdata = (FALLTHROUGH == "TRUE" && fallthrough_valid) ? fallthrough_data : rdata;

endmodule

module gray_counter (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         inc,
    output wire [ASIZE:0] gray_count
);

    reg [ASIZE:0] bin_count;
    reg [ASIZE:0] next_bin_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_count <= {ASIZE+1{1'b0}};
        end else if (inc) begin
            bin_count <= next_bin_count;
        end
    end

    assign next_bin_count = bin_count + 1;
    assign gray_count = bin_count ^ (bin_count >> 1);

endmodule

module sync_gray_counter (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [ASIZE:0] gray_count,
    output wire [ASIZE:0] sync_gray_count
);

    reg [ASIZE:0] sync_stage1;
    reg [ASIZE:0] sync_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_stage1 <= {ASIZE+1{1'b0}};
            sync_stage2 <= {ASIZE+1{1'b0}};
        end else begin
            sync_stage1 <= gray_count;
            sync_stage2 <= sync_stage1;
        end
    end

    assign sync_gray_count = sync_stage2;

endmodule

module memory_array (
    input  wire             wclk,
    input  wire             wrst_n,
    input  wire [ASIZE-1:0] waddr,
    input  wire [DSIZE-1:0] wdata,
    input  wire             wen,
    input  wire             rclk,
    input  wire             rrst_n,
    input  wire [ASIZE-1:0] raddr,
    output wire [DSIZE-1:0] rdata
);

    reg [DSIZE-1:0] mem [0:(1<<ASIZE)-1];

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem <= '{default: {DSIZE{1'b0}}};
        end else if (wen) begin
            mem[waddr] <= wdata;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= {DSIZE{1'b0}};
        end else begin
            rdata <= mem[raddr];
        end
    end

endmodule

module binary_gray #(
    parameter WIDTH = 8
)(
    input  wire [WIDTH-1:0] gray_in,
    output wire [WIDTH-1:0] bin_out
);

    assign bin_out[0] = gray_in[0];

    genvar i;
    generate
        for (i = 1; i < WIDTH; i = i + 1) begin : bin_gray_gen
            assign bin_out[i] = bin_out[i-1] ^ gray_in[i];
        end
    endgenerate

endmodule
