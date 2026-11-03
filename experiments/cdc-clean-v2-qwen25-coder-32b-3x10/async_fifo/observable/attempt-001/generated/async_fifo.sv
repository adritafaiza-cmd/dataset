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
    localparam AWIDTH = ASIZE + 1;

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    reg [AWIDTH-1:0] wptr, rptr;
    reg [AWIDTH-1:0] wptr_gray, rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_sync, rptr_gray_sync;

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
            wptr <= wptr + 1;
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Gray code conversion
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
        end else begin
            wptr_gray <= (wptr >> 1) ^ wptr;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray <= 0;
        end else begin
            rptr_gray <= (rptr >> 1) ^ rptr;
        end
    end

    // Cross-domain synchronization
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    // Binary conversion
    wire [AWIDTH-1:0] wptr_bin_sync;
    wire [AWIDTH-1:0] rptr_bin_sync;

    binary_sync #(.WIDTH(AWIDTH)) wptr_sync (
        .clk(rclk),
        .rst_n(rrst_n),
        .din(wptr_gray_sync),
        .dout(wptr_bin_sync)
    );

    binary_sync #(.WIDTH(AWIDTH)) rptr_sync (
        .clk(wclk),
        .rst_n(wrst_n),
        .din(rptr_gray_sync),
        .dout(rptr_bin_sync)
    );

    // Full and empty flags
    wire [AWIDTH-1:0] wptr_bin_sync_gray;
    wire [AWIDTH-1:0] rptr_bin_sync_gray;

    assign wptr_bin_sync_gray = (wptr_bin_sync >> 1) ^ wptr_bin_sync;
    assign rptr_bin_sync_gray = (rptr_bin_sync >> 1) ^ rptr_bin_sync;

    assign wfull = (wptr_gray == wptr_bin_sync_gray) && (wptr[AWIDTH-1] != wptr_bin_sync[AWIDTH-1]);
    assign rempty = (rptr_gray == rptr_bin_sync_gray) && (rptr[AWIDTH-1] == rptr_bin_sync[AWIDTH-1]);

    assign awfull = (wptr_gray == {~rptr_bin_sync[AWIDTH-1], rptr_bin_sync[AWIDTH-2:0]}) && (wptr[AWIDTH-1] != rptr_bin_sync[AWIDTH-1]);
    assign arempty = (rptr_gray == {~wptr_bin_sync[AWIDTH-1], wptr_bin_sync[AWIDTH-2:0]}) && (rptr[AWIDTH-1] == wptr_bin_sync[AWIDTH-1]);

    // Read data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ASIZE-1:0]];
        end
    end

endmodule

module binary_sync
    #(
        parameter WIDTH = 4
    )(
        input  wire             clk,
        input  wire             rst_n,
        input  wire [WIDTH-1:0] din,
        output reg [WIDTH-1:0]  dout
    );

    reg [WIDTH-1:0] sync_reg1;
    reg [WIDTH-1:0] sync_reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_reg1 <= 0;
            sync_reg2 <= 0;
            dout <= 0;
        end else begin
            sync_reg1 <= din;
            sync_reg2 <= sync_reg1;
            dout <= sync_reg2;
        end
    end

endmodule
