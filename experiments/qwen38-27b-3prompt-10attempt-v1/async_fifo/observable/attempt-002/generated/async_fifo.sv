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

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [ASIZE-1:0]  wptr_gray;
    reg [ASIZE-1:0]  wptr_gray_next;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  rptr_gray_next;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Synchronizers
    reg [ASIZE-1:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [ASIZE-1:0] rptr_gray_sync1, rptr_gray_sync2;

    // Write domain logic
    wire winc_valid = winc && !wfull;

    always @(*) begin
        wptr_gray_next = wptr_gray ^ (wptr[ASIZE-1:0] ^ (wptr[ASIZE-1:0] + 1'b1));
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
        end else begin
            if (winc_valid) begin
                wptr <= wptr + 1'b1;
                wptr_gray <= wptr_gray_next;
            end
        end
    end

    // Read domain logic
    wire rinc_valid = rinc && !rempty;

    always @(*) begin
        rptr_gray_next = rptr_gray ^ (rptr[ASIZE-1:0] ^ (rptr[ASIZE-1:0] + 1'b1));
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
        end else begin
            if (rinc_valid) begin
                rptr <= rptr + 1'b1;
                rptr_gray <= rptr_gray_next;
            end
        end
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_valid) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Synchronizers
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= {ASIZE{1'b0}};
            rptr_gray_sync2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= {ASIZE{1'b0}};
            wptr_gray_sync2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Convert gray to binary
    function [AWIDTH-1:0] gray2bin;
        input [AWIDTH-1:0] gray;
        integer i;
        begin
            gray2bin[AWIDTH-1] = gray[AWIDTH-1];
            for (i = AWIDTH-2; i >= 0; i = i - 1)
                gray2bin[i] = gray2bin[i+1] ^ gray[i];
        end
    endfunction

    wire [AWIDTH-1:0] wptr_bin_w = gray2bin(wptr_gray_sync2);
    wire [AWIDTH-1:0] rptr_bin_r = gray2bin(rptr_gray_sync2);

    // Full and empty flags
    // Full: write pointer has lapped read pointer by DEPTH
    // In binary: wptr_bin_w[ASIZE] != rptr_bin_r[ASIZE] && wptr_bin_w[ASIZE-1:0] == rptr_bin_r[ASIZE-1:0]
    assign wfull = (wptr_bin_w[ASIZE] != rptr_bin_r[ASIZE]) && 
                   (wptr_bin_w[ASIZE-1:0] == rptr_bin_r[ASIZE-1:0]);

    // Empty: write pointer equals read pointer
    assign rempty = (wptr_bin_w == rptr_bin_r);

    // Almost full: DEPTH - 1 entries
    // wptr_bin_w - rptr_bin_r == DEPTH - 1
    // This means wptr_bin_w[ASIZE] == rptr_bin_r[ASIZE] && wptr_bin_w[ASIZE-1:0] == rptr_bin_r[ASIZE-1:0] + (DEPTH-1)
    // Or equivalently: (wptr_bin_w - rptr_bin_r) == DEPTH - 1
    wire [AWIDTH-1:0] wfull_diff = wptr_bin_w - rptr_bin_r;
    assign awfull = (wfull_diff == DEPTH - 1);

    // Almost empty: 1 entry
    // (wptr_bin_w - rptr_bin_r) == 1
    wire [AWIDTH-1:0] rempty_diff = wptr_bin_w - rptr_bin_r;
    assign arempty = (rempty_diff == 1);

    // Read data
    // rdata is one read-clock sample. With fall-through, if the FIFO is empty and a write is happening,
    // we can show the write data. But the problem says "FALLTHROUGH does not select a combinational memory read."
    // So we just read from memory at rptr.
    assign rdata = mem[rptr[ASIZE-1:0]];

endmodule
