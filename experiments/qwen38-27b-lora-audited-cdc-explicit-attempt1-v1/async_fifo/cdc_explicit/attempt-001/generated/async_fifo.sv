// =============================================================================
// Async FIFO with Gray-coded pointer CDC
// =============================================================================

`include "async_fifo.vh"

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

    localparam DEPTH = 1 << ASIZE;
    localparam AWL   = ASIZE + 1;

    localparam AWFULL  = DEPTH - 4;
    localparam AEMPTY  = 4;

    // ------------------------------------------------------------------
    // Write domain
    // ------------------------------------------------------------------

    wire [AWL-1:0] wptr;
    wire [ASIZE-1:0] wptr_gray;
    wire [ASIZE-1:0] rptr_gray_w;
    wire [AWL-1:0] rptr_w;

    wire winc_en = winc & ~wfull;

    assign wfull   = (wptr_gray == rptr_gray_w) && (wptr[ASIZE] != rptr_w[ASIZE]);
    assign awfull  = (wptr - rptr_w) >= AWFULL;

    // ------------------------------------------------------------------
    // Read domain
    // ------------------------------------------------------------------

    wire [AWL-1:0] rptr;
    wire [ASIZE-1:0] rptr_gray;
    wire [ASIZE-1:0] wptr_gray_r;
    wire [AWL-1:0] wptr_r;

    wire rinc_en = rinc & ~rempty;

    assign rempty  = (wptr_gray_r == rptr_gray) && (wptr_r[ASIZE] == rptr[ASIZE]);
    assign arempty = (wptr_r - rptr) <= AEMPTY;

    // ------------------------------------------------------------------
    // Memory
    // ------------------------------------------------------------------

    wire [ASIZE-1:0] waddr = wptr[ASIZE-1:0];
    wire [ASIZE-1:0] raddr = rptr[ASIZE-1:0];

    wire [DSIZE-1:0] mem_rdata;

    `ifdef FPGA
    (* RAM_STYLE = "block" *)
    `endif
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    always @(posedge wclk) begin
        if (winc_en)
            mem[waddr] <= wdata;
    end

    // ------------------------------------------------------------------
    // Write pointer
    // ------------------------------------------------------------------

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWL{1'b0}};
        end else if (winc_en) begin
            wptr <= wptr + 1'b1;
        end
    end

    assign wptr_gray = wptr ^ (wptr >> 1);

    // ------------------------------------------------------------------
    // Read pointer
    // ------------------------------------------------------------------

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWL{1'b0}};
        end else if (rinc_en) begin
            rptr <= rptr + 1'b1;
        end
    end

    assign rptr_gray = rptr ^ (rptr >> 1);

    // ------------------------------------------------------------------
    // CDC: read pointer to write domain
    // ------------------------------------------------------------------

    (* ASYNC_REG = "TRUE" *)
    reg [ASIZE-1:0] rptr_gray_w_ff1;
    reg [ASIZE-1:0] rptr_gray_w_ff2;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w_ff1 <= {ASIZE{1'b0}};
            rptr_gray_w_ff2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_w_ff1 <= rptr_gray;
            rptr_gray_w_ff2 <= rptr_gray_w_ff1;
        end
    end

    assign rptr_gray_w = rptr_gray_w_ff2;
    assign rptr_w      = {rptr_gray_w_ff2[ASIZE-1], rptr_gray_w};

    // ------------------------------------------------------------------
    // CDC: write pointer to read domain
    // ------------------------------------------------------------------

    (* ASYNC_REG = "TRUE" *)
    reg [ASIZE-1:0] wptr_gray_r_ff1;
    reg [ASIZE-1:0] wptr_gray_r_ff2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r_ff1 <= {ASIZE{1'b0}};
            wptr_gray_r_ff2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_r_ff1 <= wptr_gray;
            wptr_gray_r_ff2 <= wptr_gray_r_ff1;
        end
    end

    assign wptr_gray_r = wptr_gray_r_ff2;
    assign wptr_r      = {wptr_gray_r_ff2[ASIZE-1], wptr_gray_r};

    // ------------------------------------------------------------------
    // Read data
    // ------------------------------------------------------------------

    `ifdef FPGA
    (* RAM_STYLE = "block" *)
    `endif
    reg [DSIZE-1:0] rdata_ff;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_ff <= {DSIZE{1'b0}};
        end else if (rinc_en) begin
            rdata_ff <= mem[raddr];
        end
    end

    generate
        if (FALLTHROUGH == "TRUE") begin : gen_fallthrough
            assign rdata = mem[raddr];
        end else begin : gen_no_fallthrough
            assign rdata = rdata_ff;
        end
    endgenerate

endmodule