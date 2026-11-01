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

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [ASIZE-1:0]  wptr_gray;
    reg [ASIZE-1:0]  wptr_gray_next;
    reg [ASIZE-1:0]  wptr_bin;
    reg [ASIZE-1:0]  wptr_bin_next;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  rptr_gray_next;
    reg [ASIZE-1:0]  rptr_bin;
    reg [ASIZE-1:0]  rptr_bin_next;

    // Gray code conversion
    function [ASIZE-1:0] bin2gray;
        input [ASIZE-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [ASIZE-1:0] gray2bin;
        input [ASIZE-1:0] gray;
        reg [ASIZE-1:0]   bin;
        integer i;
        begin
            bin[ASIZE-1] = gray[ASIZE-1];
            for (i = ASIZE-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;

    // Read enable
    wire rvalid = rinc & ~rempty;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
            wptr_bin <= {ASIZE{1'b0}};
        end else begin
            wptr <= wptr + (wvalid ? 1'b1 : 1'b0);
            wptr_bin <= wptr_bin_next;
            wptr_gray <= wptr_gray_next;
        end
    end

    assign wptr_bin_next = wptr_bin + (wvalid ? 1'b1 : 1'b0);
    assign wptr_gray_next = bin2gray(wptr_bin_next);

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
            rptr_bin <= {ASIZE{1'b0}};
        end else begin
            rptr <= rptr + (rvalid ? 1'b1 : 1'b0);
            rptr_bin <= rptr_bin_next;
            rptr_gray <= rptr_gray_next;
        end
    end

    assign rptr_bin_next = rptr_bin + (rvalid ? 1'b1 : 1'b0);
    assign rptr_gray_next = bin2gray(rptr_bin_next);

    // Memory write
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr_bin] <= wdata;
    end

    // Memory read
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rvalid)
            rdata_reg <= mem[rptr_bin];
    end

    assign rdata = rdata_reg;

    // Synchronize write pointer gray to read domain
    reg [ASIZE-1:0] wptr_gray_r1, wptr_gray_r2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= {ASIZE{1'b0}};
            wptr_gray_r2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end

    // Synchronize read pointer gray to write domain
    reg [ASIZE-1:0] rptr_gray_w1, rptr_gray_w2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= {ASIZE{1'b0}};
            rptr_gray_w2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end

    // Convert synchronized gray to binary
    wire [ASIZE-1:0] wptr_gray_r2_bin = gray2bin(wptr_gray_r2);
    wire [ASIZE-1:0] rptr_gray_w2_bin = gray2bin(rptr_gray_w2);

    // Full condition: write pointer gray MSB differs from read pointer gray MSB
    // and lower bits are inverted
    wire wfull_internal = (wptr_gray_r2_bin == rptr_bin) && 
                          (wptr[ASIZE] != rptr[ASIZE]);

    // Empty condition: read pointer gray equals write pointer gray
    wire rempty_internal = (rptr_gray_w2_bin == wptr_bin) && 
                           (rptr[ASIZE] == wptr[ASIZE]);

    // Almost full: one less than full
    wire awfull_internal = (wptr_gray_r2_bin == rptr_bin) && 
                           (wptr[ASIZE] != rptr[ASIZE]) &&
                           (wptr_bin == rptr_bin + 1);

    // Almost empty: one more than empty
    wire arempty_internal = (rptr_gray_w2_bin == wptr_bin) && 
                            (rptr[ASIZE] == wptr[ASIZE]) &&
                            (rptr_bin == wptr_bin + 1);

    assign wfull   = wfull_internal;
    assign awfull  = awfull_internal;
    assign rempty  = rempty_internal;
    assign arempty = arempty_internal;

endmodule
