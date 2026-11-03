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

    // Gray code conversion and synchronization
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

    // Synchronize wptr_gray to rclk domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync <= 0;
        end else begin
            wptr_gray_sync <= wptr_gray;
        end
    end

    // Synchronize rptr_gray to wclk domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync <= 0;
        end else begin
            rptr_gray_sync <= rptr_gray;
        end
    end

    // Binary conversion
    reg [AWIDTH-1:0] wptr_sync, rptr_sync;
    integer i;

    always @(*) begin
        wptr_sync = 0;
        for (i = 0; i < AWIDTH; i = i + 1) begin
            wptr_sync[i] = wptr_gray_sync[i] ^ wptr_sync[i-1];
        end
    end

    always @(*) begin
        rptr_sync = 0;
        for (i = 0; i < AWIDTH; i = i + 1) begin
            rptr_sync[i] = rptr_gray_sync[i] ^ rptr_sync[i-1];
        end
    end

    // Flags
    assign wfull = (wptr_sync[AWIDTH-1:ASIZE] != rptr_gray[AWIDTH-1:ASIZE]) && (wptr_sync[ASIZE-1:0] == rptr_gray[ASIZE-1:0]);
    assign awfull = (wptr_sync[AWIDTH-1:ASIZE] != rptr_gray_sync[AWIDTH-1:ASIZE]) && (wptr_sync[ASIZE-1:0] == rptr_gray_sync[ASIZE-1:0]);

    assign rempty = (rptr_sync[AWIDTH-1:ASIZE] == wptr_gray[AWIDTH-1:ASIZE]) && (rptr_sync[ASIZE-1:0] == wptr_gray[ASIZE-1:0]);
    assign arempty = (rptr_sync[AWIDTH-1:ASIZE] == wptr_gray_sync[AWIDTH-1:ASIZE]) && (rptr_sync[ASIZE-1:0] == wptr_gray_sync[ASIZE-1:0]);

    // Read data
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ASIZE-1:0]];
        end
    end

endmodule
