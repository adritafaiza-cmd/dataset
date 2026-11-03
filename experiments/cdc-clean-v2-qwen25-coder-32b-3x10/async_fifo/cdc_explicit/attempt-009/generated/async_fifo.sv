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
    localparam AWATERMARK = DEPTH - 2;
    localparam EWATERMARK = 1;

    reg [DSIZE-1:0] mem [DEPTH-1:0];

    reg [ASIZE:0] wptr_gray, wptr_gray_nxt, wptr_bin;
    reg [ASIZE:0] rptr_gray, rptr_gray_nxt, rptr_bin;

    reg [ASIZE:0] wptr_gray_sync1, wptr_gray_sync2;
    reg [ASIZE:0] rptr_gray_sync1, rptr_gray_sync2;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr_gray <= wptr_gray_nxt;
        end
    end

    always @(*) begin
        wptr_bin = (wptr_gray >> 1) ^ wptr_gray;
        wptr_gray_nxt = wptr_bin + 1;
        wptr_gray_nxt = (wptr_gray_nxt >> 1) ^ wptr_gray_nxt;
    end

    // Read domain logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr_gray <= rptr_gray_nxt;
        end
    end

    always @(*) begin
        rptr_bin = (rptr_gray >> 1) ^ rptr_gray;
        rptr_gray_nxt = rptr_bin + 1;
        rptr_gray_nxt = (rptr_gray_nxt >> 1) ^ rptr_gray_nxt;
    end

    // Gray code synchronization
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Write pointer in read domain
    reg [ASIZE:0] wptr_bin_rdomain;
    always @(*) begin
        wptr_bin_rdomain = (wptr_gray_sync2 >> 1) ^ wptr_gray_sync2;
    end

    // Read pointer in write domain
    reg [ASIZE:0] rptr_bin_wdomain;
    always @(*) begin
        rptr_bin_wdomain = (rptr_gray_sync2 >> 1) ^ rptr_gray_sync2;
    end

    // FIFO full and almost full
    wire [ASIZE:0] wptr_plus1;
    assign wptr_plus1 = wptr_bin + 1;
    assign wfull = (wptr_plus1 == rptr_bin_wdomain);
    assign awfull = (wptr_plus1 == (rptr_bin_wdomain + AWATERMARK));

    // FIFO empty and almost empty
    wire [ASIZE:0] rptr_plus1;
    assign rptr_plus1 = rptr_bin + 1;
    assign rempty = (rptr_bin == wptr_bin_rdomain);
    assign arempty = (rptr_plus1 == wptr_bin_rdomain);

    // Write data
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr_bin] <= wdata;
        end
    end

    // Read data
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata_reg <= mem[rptr_bin];
        end else if (FALLTHROUGH && !rempty) begin
            rdata_reg <= mem[rptr_bin];
        end
    end

    assign rdata = rdata_reg;

endmodule
