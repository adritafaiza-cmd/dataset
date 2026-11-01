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
    localparam AWIDTH_MINUS_1 = AWIDTH - 1;

    // Write domain
    reg [AWIDTH_MINUS_1:0] wptr;
    reg [AWIDTH_MINUS_1:0] wptr_gray;
    reg [AWIDTH_MINUS_1:0] wptr_gray_next;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync1;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync2;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync3;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync4;

    // Read domain
    reg [AWIDTH_MINUS_1:0] rptr;
    reg [AWIDTH_MINUS_1:0] rptr_gray;
    reg [AWIDTH_MINUS_1:0] rptr_gray_next;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync1;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync2;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync3;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync4;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wfull_internal;
    wire winc_valid;
    wire winc_accepted;

    // Read enable
    wire rempty_internal;
    wire rinc_valid;
    wire rinc_accepted;

    // Gray code conversion
    function [AWIDTH_MINUS_1:0] bin2gray;
        input [AWIDTH_MINUS_1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [AWIDTH_MINUS_1:0] gray2bin;
        input [AWIDTH_MINUS_1:0] gray;
        reg [AWIDTH_MINUS_1:0] bin;
        integer i;
        begin
            bin[AWIDTH_MINUS_1] = gray[AWIDTH_MINUS_1];
            for (i = AWIDTH_MINUS_1 - 1; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    assign wfull_internal = (wptr_gray_next == rptr_gray_w_sync4);
    assign winc_valid = winc & ~wfull_internal;
    assign winc_accepted = winc_valid;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (winc_accepted) begin
                wptr <= wptr + 1'b1;
            end
            wptr_gray <= wptr_gray_next;
        end
    end

    assign wptr_gray_next = bin2gray(wptr + (winc_accepted ? 1'b1 : 1'b0));

    // Synchronize read pointer gray code to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {AWIDTH{1'b0}};
            rptr_gray_w_sync1 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync2 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync3 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync4 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_sync1 <= rptr_gray_w;
            rptr_gray_w_sync2 <= rptr_gray_w_sync1;
            rptr_gray_w_sync3 <= rptr_gray_w_sync2;
            rptr_gray_w_sync4 <= rptr_gray_w_sync3;
        end
    end

    // Read domain logic
    assign rempty_internal = (rptr_gray_next == wptr_gray_r_sync4);
    assign rinc_valid = rinc & ~rempty_internal;
    assign rinc_accepted = rinc_valid;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (rinc_accepted) begin
                rptr <= rptr + 1'b1;
            end
            rptr_gray <= rptr_gray_next;
        end
    end

    assign rptr_gray_next = bin2gray(rptr + (rinc_accepted ? 1'b1 : 1'b0));

    // Synchronize write pointer gray code to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {AWIDTH{1'b0}};
            wptr_gray_r_sync1 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync2 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync3 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync4 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_sync1 <= wptr_gray_r;
            wptr_gray_r_sync2 <= wptr_gray_r_sync1;
            wptr_gray_r_sync3 <= wptr_gray_r_sync2;
            wptr_gray_r_sync4 <= wptr_gray_r_sync3;
        end
    end

    // Memory write
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // No action needed for memory
        end else begin
            if (winc_accepted) begin
                mem[wptr[ASIZE-1:0]] <= wdata;
            end
        end
    end

    // Memory read
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            if (rinc_accepted) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end
        end
    end

    // Outputs
    assign wfull = wfull_internal;
    assign awfull = (wptr_gray_next == rptr_gray_w_sync4) | 
                    ((wptr_gray_next == rptr_gray_w_sync4) && (wptr_gray_next[ASIZE-1:0] == rptr_gray_w_sync4[ASIZE-1:0]) && 
                     (wptr_gray_next[ASIZE-1:0] != 0));
    
    // Almost full: one less than full
    // Full when wptr_gray_next == rptr_gray_w_sync4
    // Almost full when wptr_gray_next is one ahead of rptr_gray_w_sync4 in the circular sense
    // i.e., wptr_gray_next == bin2gray(gray2bin(rptr_gray_w_sync4) + 1)
    // But simpler: almost full when the number of entries is DEPTH-1
    // Let's compute: wptr_bin = gray2bin(wptr_gray_next), rptr_bin = gray2bin(rptr_gray_w_sync4)
    // count = wptr_bin - rptr_bin (mod 2^AWIDTH)
    // full when count == DEPTH
    // almost full when count == DEPTH - 1
    
    wire [AWIDTH_MINUS_1:0] wptr_bin_w = gray2bin(wptr_gray_next);
    wire [AWIDTH_MINUS_1:0] rptr_bin_w = gray2bin(rptr_gray_w_sync4);
    wire [AWIDTH_MINUS_1:0] count_w = wptr_bin_w - rptr_bin_w;
    
    assign awfull = (count_w == DEPTH - 1);

    assign rempty = rempty_internal;
    
    // Almost empty: one more than empty
    // Empty when rptr_gray_next == wptr_gray_r_sync4
    // Almost empty when count == 1
    wire [AWIDTH_MINUS_1:0] rptr_bin_r = gray2bin(rptr_gray_next);
    wire [AWIDTH_MINUS_1:0] wptr_bin_r = gray2bin(wptr_gray_r_sync4);
    wire [AWIDTH_MINUS_1:0] count_r = wptr_bin_r - rptr_bin_r;
    
    assign arempty = (count_r == 1);

    assign rdata = rdata_reg;

endmodule
