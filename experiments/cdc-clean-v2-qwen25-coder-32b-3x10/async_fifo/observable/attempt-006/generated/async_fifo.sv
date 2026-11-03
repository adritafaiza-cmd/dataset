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

    // Gray code conversion for pointers
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

    // Synchronize gray pointers across clock domains
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

    // Binary conversion of synchronized gray pointers
    reg [AWIDTH-1:0] wptr_sync_bin, rptr_sync_bin;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_sync_bin <= 0;
        end else begin
            wptr_sync_bin <= wptr_sync_bin ^ {wptr_gray_sync[AWIDTH-1], wptr_sync_bin[AWIDTH-1:1]};
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_sync_bin <= 0;
        end else begin
            rptr_sync_bin <= rptr_sync_bin ^ {rptr_gray_sync[AWIDTH-1], rptr_sync_bin[AWIDTH-1:1]};
        end
    end

    // Full and empty flags
    wire [AWIDTH-1:0] wptr_bin_sync = wptr_sync_bin;
    wire [AWIDTH-1:0] rptr_bin_sync = rptr_sync_bin;

    assign wfull = (wptr_bin_sync[AWIDTH-1:ASIZE] != rptr_bin_sync[AWIDTH-1:ASIZE]) && (wptr_bin_sync[ASIZE-1:0] == rptr_bin_sync[ASIZE-1:0]);
    assign rempty = (wptr_bin_sync[AWIDTH-1:ASIZE] == rptr_bin_sync[AWIDTH-1:ASIZE]) && (wptr_bin_sync[ASIZE-1:0] == rptr_bin_sync[ASIZE-1:0]);

    assign awfull = (wptr_bin_sync[AWIDTH-1:ASIZE] != rptr_bin_sync[AWIDTH-1:ASIZE]) && (wptr_bin_sync[ASIZE-1:0] == rptr_bin_sync[ASIZE-1:0] - 1);
    assign arempty = (wptr_bin_sync[AWIDTH-1:ASIZE] == rptr_bin_sync[AWIDTH-1:ASIZE]) && (wptr_bin_sync[ASIZE-1:0] == rptr_bin_sync[ASIZE-1:0] + 1);

    // Read data output
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ASIZE-1:0]];
        end
    end

endmodule
