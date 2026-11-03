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

    reg [ASIZE:0] wptr_gray_rsync, rptr_gray_rsync;
    reg [ASIZE:0] wptr_gray_wsync, rptr_gray_wsync;

    // Write domain logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            wptr_gray <= wptr_gray_nxt;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            mem[0] <= 0;
        end else if (winc && !wfull) begin
            mem[wptr_bin] <= wdata;
        end
    end

    always @(*) begin
        wptr_bin = (wptr_gray >> 1) ^ wptr_gray;
        wptr_gray_nxt = wptr_gray + 1;
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
        rptr_gray_nxt = rptr_gray + 1;
    end

    // Gray code synchronization
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_wsync <= 0;
        end else begin
            rptr_gray_wsync <= rptr_gray_rsync;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_rsync <= 0;
        end else begin
            wptr_gray_rsync <= wptr_gray_wsync;
        end
    end

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr_gray_rsync <= 0;
        end else begin
            rptr_gray_rsync <= rptr_gray;
        end
    end

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr_gray_wsync <= 0;
        end else begin
            wptr_gray_wsync <= wptr_gray;
        end
    end

    // FIFO status signals
    wire [ASIZE:0] wptr_bin_wsync, rptr_bin_rsync;
    assign wptr_bin_wsync = (wptr_gray_wsync >> 1) ^ wptr_gray_wsync;
    assign rptr_bin_rsync = (rptr_gray_rsync >> 1) ^ rptr_gray_rsync;

    assign wfull = (wptr_bin_wsync == {~rptr_bin_rsync[ASIZE], rptr_bin_rsync[ASIZE-1:0]});
    assign awfull = (wptr_bin_wsync == {~rptr_bin_rsync[ASIZE], rptr_bin_rsync[ASIZE-1:0] + AWATERMARK});

    assign rempty = (rptr_bin == wptr_bin_wsync);
    assign arempty = (rptr_bin == wptr_bin_wsync + EWATERMARK);

    // Read data output
    reg [DSIZE-1:0] rdata_reg;
    reg [DSIZE-1:0] rdata_reg2;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
            rdata_reg2 <= 0;
        end else if (rinc && !rempty) begin
            rdata_reg <= mem[rptr_bin];
            rdata_reg2 <= rdata_reg;
        end
    end

    assign rdata = (FALLTHROUGH == "TRUE") ? rdata_reg : rdata_reg2;

endmodule
