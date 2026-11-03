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
    reg [ASIZE-1:0]  rptr_gray_w;
    reg [ASIZE-1:0]  rptr_gray_w_sync1;
    reg [ASIZE-1:0]  rptr_gray_w_sync2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [ASIZE-1:0]  rptr_gray;
    reg [ASIZE-1:0]  wptr_gray_r;
    reg [ASIZE-1:0]  wptr_gray_r_sync1;
    reg [ASIZE-1:0]  wptr_gray_r_sync2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Read data register
    reg [DSIZE-1:0] rdata_reg;

    // Gray code conversion
    function [ASIZE-1:0] bin2gray;
        input [ASIZE-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write domain logic
    wire winc_eff = winc & ~wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {ASIZE{1'b0}};
        end else if (winc_eff) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr[ASIZE-1:0] + 1'b1);
        end
    end

    // Synchronize read pointer gray code to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {ASIZE{1'b0}};
            rptr_gray_w_sync1 <= {ASIZE{1'b0}};
            rptr_gray_w_sync2 <= {ASIZE{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_sync1 <= rptr_gray_w;
            rptr_gray_w_sync2 <= rptr_gray_w_sync1;
        end
    end

    // Write full and almost full
    wire [ASIZE-1:0] wptr_gray_next = wptr_gray;
    wire [ASIZE-1:0] rptr_gray_sync = rptr_gray_w_sync2;

    // Full condition: write pointer gray code MSB differs from read pointer gray code MSB,
    // and the remaining bits are equal
    wire wfull_internal = (wptr_gray[ASIZE-1] != rptr_gray_sync[ASIZE-1]) &&
                          (wptr_gray[ASIZE-2:0] == rptr_gray_sync[ASIZE-2:0]);

    // Almost full: one less than full
    wire [ASIZE-1:0] wptr_gray_afull = wptr_gray;
    wire awfull_internal = (wptr_gray_afull[ASIZE-1] != rptr_gray_sync[ASIZE-1]) &&
                           (wptr_gray_afull[ASIZE-2:0] == rptr_gray_sync[ASIZE-2:0] + 1'b1);

    assign wfull = wfull_internal;
    assign awfull = awfull_internal;

    // Write to memory
    always @(posedge wclk) begin
        if (winc_eff) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Read domain logic
    wire rinc_eff = rinc & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {ASIZE{1'b0}};
        end else if (rinc_eff) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr[ASIZE-1:0] + 1'b1);
        end
    end

    // Synchronize write pointer gray code to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {ASIZE{1'b0}};
            wptr_gray_r_sync1 <= {ASIZE{1'b0}};
            wptr_gray_r_sync2 <= {ASIZE{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_sync1 <= wptr_gray_r;
            wptr_gray_r_sync2 <= wptr_gray_r_sync1;
        end
    end

    // Read empty and almost empty
    wire [ASIZE-1:0] wptr_gray_sync = wptr_gray_r_sync2;
    wire [ASIZE-1:0] rptr_gray_cur = rptr_gray;

    // Empty condition: write pointer gray code equals read pointer gray code
    wire rempty_internal = (wptr_gray_sync == rptr_gray_cur);

    // Almost empty: one more than empty
    wire arempty_internal = (wptr_gray_sync == rptr_gray_cur + 1'b1);

    assign rempty = rempty_internal;
    assign arempty = arempty_internal;

    // Read data
    // When FALLTHROUGH is TRUE, rdata presents the oldest unread word when not empty
    // When FALLTHROUGH is FALSE, rdata is registered and updated on accepted read
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = mem[rptr[ASIZE-1:0]];
        end else begin
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    rdata_reg <= {DSIZE{1'b0}};
                end else if (rinc_eff) begin
                    rdata_reg <= mem[rptr[ASIZE-1:0]];
                end
            end
            assign rdata = rdata_reg;
        end
    endgenerate

endmodule
