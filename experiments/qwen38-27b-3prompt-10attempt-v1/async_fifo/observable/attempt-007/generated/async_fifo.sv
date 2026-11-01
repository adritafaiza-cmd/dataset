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

    localparam AWIDTH = ASIZE + 1;
    localparam DEPTH  = 1 << ASIZE;
    localparam AWFULL_THRESH = DEPTH - 1;
    localparam AEMPTY_THRESH = 1;

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] wptr_gray;
    reg [AWIDTH-1:0] rptr_gray_w;
    reg [AWIDTH-1:0] rptr_gray_w_d1;
    reg [AWIDTH-1:0] rptr_gray_w_d2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_r;
    reg [AWIDTH-1:0] wptr_gray_r_d1;
    reg [AWIDTH-1:0] wptr_gray_r_d2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write side logic
    wire winc_valid = winc & ~wfull;
    wire [AWIDTH-1:0] wptr_next = wptr + 1'b1;
    wire [AWIDTH-1:0] wptr_gray_next = (wptr_next ^ wptr) >> 1;

    // Read side logic
    wire rinc_valid = rinc & ~rempty;
    wire [AWIDTH-1:0] rptr_next = rptr + 1'b1;
    wire [AWIDTH-1:0] rptr_gray_next = (rptr_next ^ rptr) >> 1;

    // Full/Empty detection in write domain
    wire [AWIDTH-1:0] wptr_gray_sync = rptr_gray_w_d2;
    wire wfull_internal = (wptr_gray == wptr_gray_sync) && (wptr[ASIZE-1:0] != rptr_gray_w_d2[ASIZE-1:0]);
    wire awfull_internal = (wptr[ASIZE-1:0] == rptr_gray_w_d2[ASIZE-1:0]) && (wptr[ASIZE] != rptr_gray_w_d2[ASIZE]);

    // Full/Empty detection in read domain
    wire [AWIDTH-1:0] rptr_gray_sync = wptr_gray_r_d2;
    wire rempty_internal = (rptr_gray == rptr_gray_sync);
    wire arempty_internal = (rptr[ASIZE-1:0] == wptr_gray_r_d2[ASIZE-1:0]) && (rptr[ASIZE] == wptr_gray_r_d2[ASIZE]);

    // Outputs
    assign wfull = wfull_internal;
    assign awfull = awfull_internal;
    assign rempty = rempty_internal;
    assign arempty = arempty_internal;

    // Memory write
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (winc_valid) begin
                mem[wptr[ASIZE-1:0]] <= wdata;
                wptr <= wptr_next;
                wptr_gray <= wptr_gray_next;
            end
        end
    end

    // Gray code synchronization to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {AWIDTH{1'b0}};
            wptr_gray_r_d1 <= {AWIDTH{1'b0}};
            wptr_gray_r_d2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_d1 <= wptr_gray_r;
            wptr_gray_r_d2 <= wptr_gray_r_d1;
        end
    end

    // Gray code synchronization to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {AWIDTH{1'b0}};
            rptr_gray_w_d1 <= {AWIDTH{1'b0}};
            rptr_gray_w_d2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_d1 <= rptr_gray_w;
            rptr_gray_w_d2 <= rptr_gray_w_d1;
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (rinc_valid) begin
                rptr <= rptr_next;
                rptr_gray <= rptr_gray_next;
            end
        end
    end

    // Read data output
    // FALLTHROUGH: if not empty and read is requested, output the data at the current read pointer
    // Otherwise, output the data at the current read pointer (registered)
    // Since rdata is one read-clock sample, we register the read data
    reg [DSIZE-1:0] rdata_reg;
    
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            if (rinc_valid) begin
                rdata_reg <= mem[rptr[ASIZE-1:0]];
            end
        end
    end

    assign rdata = rdata_reg;

endmodule
