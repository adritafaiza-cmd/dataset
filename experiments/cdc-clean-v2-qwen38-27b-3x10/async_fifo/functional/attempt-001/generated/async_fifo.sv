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
    localparam FULL_THRESH = DEPTH - 1;
    localparam EMPTY_THRESH = 1;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] wptr_gray;
    reg [AWIDTH-1:0] rptr_gray_w;
    reg [AWIDTH-1:0] rptr_gray_w_sync1;
    reg [AWIDTH-1:0] rptr_gray_w_sync2;
    reg [AWIDTH-1:0] rptr_bin_w;
    reg              wfull_reg;
    reg              awfull_reg;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_r;
    reg [AWIDTH-1:0] wptr_gray_r_sync1;
    reg [AWIDTH-1:0] wptr_gray_r_sync2;
    reg [AWIDTH-1:0] wptr_bin_r;
    reg              rempty_reg;
    reg              arempty_reg;
    reg [DSIZE-1:0]  rdata_reg;

    // Gray code conversion functions
    function [AWIDTH-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [AWIDTH-1:0] gray2bin;
        input [AWIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[AWIDTH-1] = gray[AWIDTH-1];
            for (i = AWIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray[i] ^ gray2bin[i+1];
        end
    endfunction

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
            rptr_gray_w <= {AWIDTH{1'b0}};
            rptr_gray_w_sync1 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync2 <= {AWIDTH{1'b0}};
            rptr_bin_w <= {AWIDTH{1'b0}};
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else begin
            // Synchronize read pointer gray code
            rptr_gray_w_sync1 <= rptr_gray_w;
            rptr_gray_w_sync2 <= rptr_gray_w_sync1;
            rptr_bin_w <= gray2bin(rptr_gray_w_sync2);

            // Update write pointer
            if (winc && !wfull_reg) begin
                wptr <= wptr + 1'b1;
                wptr_gray <= bin2gray(wptr + 1'b1);
            end

            // Full condition: write pointer has lapped read pointer
            // In gray code, full when wptr_gray == rptr_gray_sync2 with MSB difference
            // Standard: full when (wptr_gray == rptr_gray_sync2) and (wptr[ASIZE] != rptr_bin_w[ASIZE])
            // Actually, the standard check is: wptr_gray == rptr_gray_sync2 and wptr[ASIZE] != rptr_bin_w[ASIZE]
            // But since we're comparing gray codes, we need to be careful.
            // The standard approach: full when wptr_gray == rptr_gray_sync2 and the MSB of wptr differs from MSB of rptr_bin_w
            // Let's use: wfull = (wptr_gray == rptr_gray_w_sync2) && (wptr[ASIZE] != rptr_bin_w[ASIZE])
            // But wptr is the current value before increment. Let's think again.
            
            // Actually, the standard Cummings FIFO uses:
            // wfull = (wptr_gray == rptr_gray_sync2) && (wptr[ASIZE] != rptr_bin_w[ASIZE])
            // where wptr is the current write pointer (before this cycle's increment)
            
            // Let's compute wfull combinationally from current state
            // wfull_reg is registered version
        end
    end

    // Compute wfull and awfull in write domain
    // wfull: write pointer has lapped read pointer
    // In gray code comparison: wfull when wptr_gray == rptr_gray_w_sync2 and wptr[ASIZE] != rptr_bin_w[ASIZE]
    wire wfull_comb = (wptr_gray == rptr_gray_w_sync2) && (wptr[ASIZE] != rptr_bin_w[ASIZE]);
    
    // awfull: approaching full, i.e., DEPTH - 1 entries in FIFO
    // Number of entries = wptr - rptr_bin_w (mod DEPTH)
    // awfull when (wptr - rptr_bin_w) == FULL_THRESH
    wire [AWIDTH-1:0] wdiff = wptr - rptr_bin_w;
    wire awfull_comb = (wdiff == FULL_THRESH[AWIDTH-1:0]);

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wfull_reg <= 1'b0;
            awfull_reg <= 1'b0;
        end else begin
            wfull_reg <= wfull_comb;
            awfull_reg <= awfull_comb;
        end
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
            wptr_gray_r <= {AWIDTH{1'b0}};
            wptr_gray_r_sync1 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync2 <= {AWIDTH{1'b0}};
            wptr_bin_r <= {AWIDTH{1'b0}};
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            // Synchronize write pointer gray code
            wptr_gray_r_sync1 <= wptr_gray_r;
            wptr_gray_r_sync2 <= wptr_gray_r_sync1;
            wptr_bin_r <= gray2bin(wptr_gray_r_sync2);

            // Update read pointer
            if (rinc && !rempty_reg) begin
                rptr <= rptr + 1'b1;
                rptr_gray <= bin2gray(rptr + 1'b1);
            end

            // Read data
            if (rinc && !rempty_reg) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end
        end
    end

    // Compute rempty and arempty in read domain
    // rempty: read pointer == write pointer
    wire rempty_comb = (rptr_gray == wptr_gray_r_sync2);
    
    // arempty: approaching empty, i.e., 1 entry in FIFO
    wire [AWIDTH-1:0] rdiff = wptr_bin_r - rptr;
    wire arempty_comb = (rdiff == EMPTY_THRESH[AWIDTH-1:0]);

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rempty_reg <= 1'b1;
            arempty_reg <= 1'b1;
        end else begin
            rempty_reg <= rempty_comb;
            arempty_reg <= arempty_comb;
        end
    end

    // Outputs
    assign wfull = wfull_reg;
    assign awfull = awfull_reg;
    assign rempty = rempty_reg;
    assign arempty = arempty_reg;
    assign rdata = rdata_reg;

    // Write to memory
    always @(posedge wclk) begin
        if (winc && !wfull_reg) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

endmodule
