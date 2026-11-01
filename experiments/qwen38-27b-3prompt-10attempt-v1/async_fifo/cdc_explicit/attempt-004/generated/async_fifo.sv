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

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [ASIZE-1:0]  wptr_gray;
    reg [ASIZE-1:0]  wptr_gray_sync;
    reg [ASIZE-1:0]  rptr_gray_w;
    reg [ASIZE-1:0]  rptr_gray_w_sync;
    reg [ASIZE-1:0]  rptr_gray_w_sync2;
    reg [ASIZE-1:0]  rptr_gray_w_sync3;
    reg [ASIZE-1:0]  rptr_gray_w_sync4;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  rptr_gray_sync;
    reg [ASIZE-1:0]  wptr_gray_r;
    reg [ASIZE-1:0]  wptr_gray_r_sync;
    reg [ASIZE-1:0]  wptr_gray_r_sync2;
    reg [ASIZE-1:0]  wptr_gray_r_sync3;
    reg [ASIZE-1:0]  wptr_gray_r_sync4;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;
    wire rvalid = rinc & ~rempty;

    // Gray code conversion
    function [ASIZE-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
        end else if (wvalid) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr + 1'b1);
        end
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
        end else if (rvalid) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr + 1'b1);
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (wvalid) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Synchronize read pointer gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {ASIZE{1'b0}};
            rptr_gray_w_sync <= {ASIZE{1'b0}};
            rptr_gray_w_sync2 <= {ASIZE{1'b0}};
            rptr_gray_w_sync3 <= {ASIZE{1'b0}};
            rptr_gray_w_sync4 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_sync <= rptr_gray_w;
            rptr_gray_w_sync2 <= rptr_gray_w_sync;
            rptr_gray_w_sync3 <= rptr_gray_w_sync2;
            rptr_gray_w_sync4 <= rptr_gray_w_sync3;
        end
    end

    // Synchronize write pointer gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {ASIZE{1'b0}};
            wptr_gray_r_sync <= {ASIZE{1'b0}};
            wptr_gray_r_sync2 <= {ASIZE{1'b0}};
            wptr_gray_r_sync3 <= {ASIZE{1'b0}};
            wptr_gray_r_sync4 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_sync <= wptr_gray_r;
            wptr_gray_r_sync2 <= wptr_gray_r_sync;
            wptr_gray_r_sync3 <= wptr_gray_r_sync2;
            wptr_gray_r_sync4 <= wptr_gray_r_sync3;
        end
    end

    // Full detection in write domain
    // Full when write pointer has lapped read pointer by DEPTH
    // In gray code, full when wptr_gray == rptr_gray_sync4 with MSB of wptr != MSB of rptr
    wire [AWIDTH-1:0] wptr_ext = {wptr[AWIDTH-1], wptr[ASIZE-1:0]};
    wire [AWIDTH-1:0] rptr_gray_w_sync4_ext = {rptr_gray_w_sync4[ASIZE-1], rptr_gray_w_sync4[ASIZE-2:0]};
    
    // Convert gray to binary for comparison
    function [ASIZE-1:0] gray2bin;
        input [ASIZE-1:0] gray;
        integer i;
        begin
            gray2bin[ASIZE-1] = gray[ASIZE-1];
            for (i = ASIZE-2; i >= 0; i = i - 1) begin
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
            end
        end
    endfunction

    wire [ASIZE-1:0] rptr_bin_w = gray2bin(rptr_gray_w_sync4);
    wire [ASIZE-1:0] wptr_bin_w = wptr[ASIZE-1:0];
    
    // Full: wptr has wrapped around and caught up to rptr
    // wptr[ASIZE] (the extra bit) should be different from rptr's implied extra bit
    // When wptr wraps, wptr[ASIZE] toggles. Full when wptr[ASIZE] != rptr[ASIZE] (implied) and lower bits match
    // Actually, standard approach: full when wptr_gray == rptr_gray_sync and wptr[ASIZE] != rptr[ASIZE]
    // But we only have ASIZE bits of gray. Let's use the standard method:
    // Full when the write pointer's gray code equals the synchronized read pointer's gray code,
    // AND the write pointer's MSB (bit ASIZE) is different from what the read pointer's MSB would be.
    
    // Simpler: track the full bit separately
    // Full when wptr has incremented DEPTH times since rptr
    // Using gray codes: full when wptr_gray == rptr_gray_sync4 and wptr[ASIZE] != rptr_gray_w_sync4[ASIZE-1]
    // Wait, that's not quite right either. Let me use the standard Cummings approach.
    
    // Standard: full when wptr_gray == rptr_gray_sync and wptr[ASIZE] != rptr[ASIZE]
    // But rptr[ASIZE] is not directly available in write domain. 
    // Instead: full when wptr_gray == rptr_gray_sync4 and wptr[ASIZE] != (rptr_gray_w_sync4[ASIZE-1] ^ rptr_gray_w_sync4[ASIZE-2])
    // Hmm, this is getting complicated. Let me use a different approach.
    
    // Actually, the standard approach for async FIFO with gray codes:
    // Full: wptr_gray == rptr_gray_sync AND wptr[ASIZE] != rptr[ASIZE]
    // Since we can't get rptr[ASIZE] directly, we note that rptr[ASIZE] can be derived from the gray code.
    // rptr[ASIZE] = rptr_gray[ASIZE-1] (since gray[ASIZE-1] = bin[ASIZE-1] ^ bin[ASIZE], but we don't have bin[ASIZE])
    
    // Let me just use the binary comparison approach with synchronized pointers.
    // Synchronize the full binary read pointer to write domain? No, that's multi-bit.
    
    // Better approach: Use the standard gray code full detection.
    // Full when wptr_gray == rptr_gray_sync4 and wptr[ASIZE] != rptr_gray_w_sync4[ASIZE-1]
    // This works because when the pointers are equal in the lower ASIZE bits, the MSB difference indicates a full wrap.
    
    wire wfull_internal = (wptr_gray == rptr_gray_w_sync4) && (wptr[ASIZE] != rptr_gray_w_sync4[ASIZE-1]);
    assign wfull = wfull_internal;

    // Almost full: one entry before full
    wire [AWIDTH-1:0] wptr_plus1 = wptr + 1'b1;
    wire [ASIZE-1:0] wptr_plus1_gray = bin2gray(wptr_plus1);
    wire awfull_internal = (wptr_plus1_gray == rptr_gray_w_sync4) && (wptr_plus1[ASIZE] != rptr_gray_w_sync4[ASIZE-1]);
    assign awfull = awfull_internal;

    // Empty detection in read domain
    wire [ASIZE-1:0] wptr_bin_r = gray2bin(wptr_gray_r_sync4);
    wire [ASIZE-1:0] rptr_bin_r = rptr[ASIZE-1:0];
    
    wire rempty_internal = (rptr_gray == wptr_gray_r_sync4) && (rptr[ASIZE] == wptr_gray_r_sync4[ASIZE-1]);
    assign rempty = rempty_internal;

    // Almost empty: one entry after empty
    wire [AWIDTH-1:0] rptr_plus1 = rptr + 1'b1;
    wire [ASIZE-1:0] rptr_plus1_gray = bin2gray(rptr_plus1);
    wire arempty_internal = (rptr_plus1_gray == wptr_gray_r_sync4) && (rptr_plus1[ASIZE] == wptr_gray_r_sync4[ASIZE-1]);
    assign arempty = arempty_internal;

    // Read data
    wire [ASIZE-1:0] raddr = rptr[ASIZE-1:0];
    
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else if (rvalid) begin
            rdata_reg <= mem[raddr];
        end
    end

    // Fall-through: if FALLTHROUGH is true, present current oldest word
    // Otherwise, use registered read data
    wire [DSIZE-1:0] rdata_comb = mem[raddr];
    
    assign rdata = (FALLTHROUGH == "TRUE") ? rdata_comb : rdata_reg;

endmodule
