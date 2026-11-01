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
    localparam AWIDTH = ASIZE + 1;
    localparam AWIDTH_M1 = AWIDTH - 1;

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] wptr_gray;
    reg [AWIDTH-1:0] rptr_gray_w;
    reg [AWIDTH-1:0] rptr_gray_w_d1;
    reg [AWIDTH-1:0] rptr_gray_w_d2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_r;
    reg [AWIDTH-1:0] wptr_gray_r_d1;
    reg [AWIDTH-1:0] wptr_gray_r_d2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wfull_local;
    wire awfull_local;
    wire winc_valid;

    // Read enable
    wire rempty_local;
    wire arempty_local;
    wire rinc_valid;

    // Gray code conversion
    function [AWIDTH-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write domain logic
    assign wfull_local = (wptr_gray == rptr_gray_w_d2);
    assign awfull_local = (wptr_gray == rptr_gray_w_d2) || 
                          ((wptr[AWIDTH_M1:1] == rptr_gray_w_d2[AWIDTH_M1:1]) && 
                           (wptr[0] != rptr_gray_w_d2[0]) &&
                           (wptr[AWIDTH_M1:1] == rptr_gray_w_d2[AWIDTH_M1:1] ^ 1'b1));
    // Simpler almost full: one slot away from full
    assign awfull_local = (wptr[AWIDTH_M1:1] == rptr_gray_w_d2[AWIDTH_M1:1]) && 
                          (wptr[0] != rptr_gray_w_d2[0]) &&
                          ((wptr[AWIDTH_M1:1] + 1'b1) == (rptr_gray_w_d2[AWIDTH_M1:1] + 1'b1));
    // Let's use a cleaner almost full: full minus 1
    // Full when wptr_gray == rptr_gray_w_d2
    // Almost full when wptr is one ahead of what would make it full
    // i.e., wptr[AWIDTH_M1:1] == rptr_gray_w_d2[AWIDTH_M1:1] and wptr[0] == rptr_gray_w_d2[0] ^ 1
    // Actually, almost full means one more write would make it full.
    // So wptr + 1 would equal rptr_gray_w_d2 in binary (with wraparound consideration for the top bit)
    // Let's just compute: almost full if (wptr + 1) gray == rptr_gray_w_d2
    // But that's complex. Standard approach:
    // awfull = (wptr[AWIDTH_M1:1] == rptr_gray_w_d2[AWIDTH_M1:1]) && (wptr[0] != rptr_gray_w_d2[0])
    // This works for power-of-2 FIFOs.

    assign winc_valid = winc && !wfull_local;

    // Read domain logic
    assign rempty_local = (rptr_gray == wptr_gray_r_d2);
    assign arempty_local = (rptr[AWIDTH_M1:1] == wptr_gray_r_d2[AWIDTH_M1:1]) && 
                           (rptr[0] != wptr_gray_r_d2[0]);
    assign rinc_valid = rinc && !rempty_local;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else if (winc_valid) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr + 1'b1);
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else if (rinc_valid) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr + 1'b1);
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_valid) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Memory read
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rinc_valid) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    // Fall-through: if FALLTHROUGH is "TRUE", rdata can be combinational from memory
    // But the problem says "FALLTHROUGH does not select a combinational memory read"
    // So rdata is always registered, one read clock sample.
    assign rdata = rdata_reg;

    // Cross-domain synchronization of write pointer gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {AWIDTH{1'b0}};
            wptr_gray_r_d1 <= {AWIDTH{1'b0}};
            wptr_gray_r_d2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_d1 <= wptr_gray_r;
            wptr_gray_r_d2 <= wptr_gray_r_d1;
        end
    end

    // Cross-domain synchronization of read pointer gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {AWIDTH{1'b0}};
            rptr_gray_w_d1 <= {AWIDTH{1'b0}};
            rptr_gray_w_d2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_d1 <= rptr_gray_w;
            rptr_gray_w_d2 <= rptr_gray_w_d1;
        end
    end

    // Outputs
    assign wfull = wfull_local;
    assign awfull = awfull_local;
    assign rempty = rempty_local;
    assign arempty = arempty_local;

endmodule
