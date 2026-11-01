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

    localparam AWIDTH = ASIZE + 1;
    localparam DEPTH  = 1 << ASIZE;
    localparam AWFULL_THRESH = DEPTH - 1;
    localparam AEMPTY_THRESH = 1;

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [ASIZE-1:0]  wptr_gray;
    reg [ASIZE-1:0]  wptr_gray_next;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  rptr_gray_next;

    // Synchronizers
    reg [ASIZE-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [ASIZE-1:0] rptr_gray_sync1, rptr_gray_sync2;

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
    function [ASIZE-1:0] bin2gray;
        input [ASIZE-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
        end else if (winc_valid) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= wptr_gray_next;
        end
    end

    assign wptr_gray_next = bin2gray(wptr[ASIZE-1:0] + 1'b1);

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
        end else if (rinc_valid) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= rptr_gray_next;
        end
    end

    assign rptr_gray_next = bin2gray(rptr[ASIZE-1:0] + 1'b1);

    // Synchronize write pointer gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= {ASIZE{1'b0}};
            wptr_gray_sync2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Synchronize read pointer gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= {ASIZE{1'b0}};
            rptr_gray_sync2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Full condition: write pointer gray equals read pointer gray with MSB inverted
    assign wfull_local = (wptr_gray == {~wptr[ASIZE], wptr_gray_sync2[ASIZE-1:0]});
    assign awfull_local = (wptr[ASIZE-1:0] - rptr_gray_sync2[ASIZE-1:0] == AWFULL_THRESH[ASIZE-1:0]);

    // Empty condition: read pointer gray equals write pointer gray
    assign rempty_local = (rptr_gray == wptr_gray_sync2);
    assign arempty_local = (wptr_gray_sync2[ASIZE-1:0] - rptr[ASIZE-1:0] == AEMPTY_THRESH[ASIZE-1:0]);

    // Valid write/read
    assign winc_valid = winc & ~wfull_local;
    assign rinc_valid = rinc & ~rempty_local;

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

    assign rdata = rdata_reg;

    // Outputs
    assign wfull   = wfull_local;
    assign awfull  = awfull_local;
    assign rempty  = rempty_local;
    assign arempty = arempty_local;

endmodule
