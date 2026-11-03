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

    localparam AWIDTH = ASIZE;
    localparam DEPTH  = 1 << ASIZE;
    localparam PTRW   = ASIZE + 1;

    // Write-domain registers
    reg [DSIZE-1:0] mem [0:DEPTH-1];
    reg [PTRW-1:0]  wptr;
    reg [PTRW-1:0]  rptr_w;
    reg [PTRW-1:0]  rptr_w_sync0;
    reg [PTRW-1:0]  rptr_w_sync1;

    // Read-domain registers
    reg [PTRW-1:0]  rptr;
    reg [PTRW-1:0]  wptr_r;
    reg [PTRW-1:0]  wptr_r_sync0;
    reg [PTRW-1:0]  wptr_r_sync1;

    // Write-domain logic
    wire [PTRW-1:0] wptr_next = wptr + 1'b1;
    wire            wfull_raw = (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]) &&
                                (wptr[ASIZE]     != rptr_w[ASIZE]);
    wire            awfull_raw = (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]) &&
                                 (wptr[ASIZE]     != rptr_w[ASIZE]) &&
                                 (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]) &&
                                 (wptr[ASIZE-1:0] == {ASIZE{1'b1}} + (DEPTH - 1));
    // awfull: almost full, i.e., only 1 slot left
    wire            awfull_raw2 = (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]) &&
                                  (wptr[ASIZE]     != rptr_w[ASIZE]) &&
                                  (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0] + (DEPTH - 1));

    wire            winc_eff = winc && !wfull_raw;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {PTRW{1'b0}};
            rptr_w_sync0 <= {PTRW{1'b0}};
            rptr_w_sync1 <= {PTRW{1'b0}};
        end else begin
            rptr_w_sync0 <= rptr_w;
            rptr_w_sync1 <= rptr_w_sync0;
            if (winc_eff)
                wptr <= wptr_next;
        end
    end

    assign rptr_w = rptr_w_sync1;

    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    assign wfull  = wfull_raw;
    assign awfull = awfull_raw2;

    // Read-domain logic
    wire [PTRW-1:0] rptr_next = rptr + 1'b1;
    wire            rempty_raw = (rptr == wptr_r);
    wire            arempty_raw = (rptr[ASIZE-1:0] == wptr_r[ASIZE-1:0]) &&
                                  (rptr[ASIZE]     == wptr_r[ASIZE]) &&
                                  (rptr[ASIZE-1:0] == wptr_r[ASIZE-1:0] + 1);
    // arempty: almost empty, i.e., only 1 entry available
    wire            arempty_raw2 = (rptr[ASIZE-1:0] == wptr_r[ASIZE-1:0]) &&
                                   (rptr[ASIZE]     == wptr_r[ASIZE]) &&
                                   (rptr[ASIZE-1:0] == wptr_r[ASIZE-1:0] + 1);

    wire            rinc_eff = rinc && !rempty_raw;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {PTRW{1'b0}};
            wptr_r_sync0 <= {PTRW{1'b0}};
            wptr_r_sync1 <= {PTRW{1'b0}};
        end else begin
            wptr_r_sync0 <= wptr_r;
            wptr_r_sync1 <= wptr_r_sync0;
            if (rinc_eff)
                rptr <= rptr_next;
        end
    end

    assign wptr_r = wptr_r_sync1;

    assign rdata   = mem[rptr[ASIZE-1:0]];
    assign rempty  = rempty_raw;
    assign arempty = arempty_raw2;

endmodule
