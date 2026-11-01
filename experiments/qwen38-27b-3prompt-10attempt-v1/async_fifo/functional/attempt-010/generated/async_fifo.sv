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
    localparam AWFULL_THRESH = DEPTH - 2;
    localparam AEMPTY_THRESH = 2;

    // Write pointer (write domain)
    reg [ASIZE:0] wptr;
    // Read pointer (read domain)
    reg [ASIZE:0] rptr;

    // Synchronizers
    reg [ASIZE:0] rptr_wsync1, rptr_wsync2;
    reg [ASIZE:0] wptr_rsync1, wptr_rsync2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write enable
    wire wvalid = winc & ~wfull;
    wire rvalid = rinc & ~rempty;

    // Write pointer increment
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= 0;
        else if (wvalid)
            wptr <= wptr + 1;
    end

    // Read pointer increment
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= 0;
        else if (rvalid)
            rptr <= rptr + 1;
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_wsync1 <= 0;
            rptr_wsync2 <= 0;
        end else begin
            rptr_wsync1 <= rptr;
            rptr_wsync2 <= rptr_wsync1;
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_rsync1 <= 0;
            wptr_rsync2 <= 0;
        end else begin
            wptr_rsync1 <= wptr;
            wptr_rsync2 <= wptr_rsync1;
        end
    end

    // Full condition: write pointer has lapped read pointer by DEPTH
    // In binary with ASIZE+1 bits, full when upper bits differ and lower bits equal
    wire wfull = (wptr[ASIZE] != rptr_wsync2[ASIZE]) && 
                 (wptr[ASIZE-1:0] == rptr_wsync2[ASIZE-1:0]);

    // Empty condition: read pointer has lapped write pointer by DEPTH
    wire rempty = (rptr[ASIZE] != wptr_rsync2[ASIZE]) && 
                  (rptr[ASIZE-1:0] == wptr_rsync2[ASIZE-1:0]);

    // Almost full: number of entries >= AWFULL_THRESH
    // Number of entries = wptr - rptr_wsync2 (mod 2^(ASIZE+1))
    // We can compute the difference in the write domain
    wire [ASIZE:0] wcount = wptr - rptr_wsync2;
    wire awfull = (wcount >= AWFULL_THRESH);

    // Almost empty: number of entries <= AEMPTY_THRESH
    wire [ASIZE:0] rcount = wptr_rsync2 - rptr;
    wire arempty = (rcount <= AEMPTY_THRESH);

    // Memory write
    always @(posedge wclk) begin
        if (wvalid)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read data output
    // For FALLTHROUGH, rdata is the current oldest unread word (combinational from memory)
    // Otherwise, rdata is registered on accepted read
    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rdata_reg <= 0;
        else if (rvalid)
            rdata_reg <= mem[rptr[ASIZE-1:0]];
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? mem[rptr[ASIZE-1:0]] : rdata_reg;

endmodule
