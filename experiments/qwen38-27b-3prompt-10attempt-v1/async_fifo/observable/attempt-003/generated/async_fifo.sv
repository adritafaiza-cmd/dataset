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
    localparam AWIDTH_MINUS_1 = AWIDTH - 1;

    // Write domain
    reg [AWIDTH_MINUS_1:0] wptr;
    reg [AWIDTH_MINUS_1:0] wptr_gray;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync1;
    reg [AWIDTH_MINUS_1:0] rptr_gray_w_sync2;

    // Read domain
    reg [AWIDTH_MINUS_1:0] rptr;
    reg [AWIDTH_MINUS_1:0] rptr_gray;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync1;
    reg [AWIDTH_MINUS_1:0] wptr_gray_r_sync2;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Gray code conversion
    function [AWIDTH_MINUS_1:0] bin2gray;
        input [AWIDTH_MINUS_1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    // Write domain logic
    wire winc_eff = winc & ~wfull;
    wire wfull_internal;
    wire awfull_internal;

    // Full condition: write pointer gray equals read pointer gray with MSB and MSB-1 inverted
    assign wfull_internal = (wptr_gray == {~rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], rptr_gray_w_sync2[AWIDTH_MINUS_3:0]});
    assign awfull_internal = (wptr_gray == {~rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], rptr_gray_w_sync2[AWIDTH_MINUS_3:0]}) | 
                              (wptr_gray == {~rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], rptr_gray_w_sync2[AWIDTH_MINUS_3:0]});

    // Actually, let's use the standard full condition:
    // Full when wptr_gray == {~rptr_gray[MSB:MSB-1], rptr_gray[MSB-2:0]}
    // This means the write pointer has wrapped around and caught up to the read pointer
    assign wfull_internal = (wptr_gray == {~rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], rptr_gray_w_sync2[AWIDTH_MINUS_3:0]});
    
    // Almost full: one entry away from full
    assign awfull_internal = (wptr_gray == {~rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], rptr_gray_w_sync2[AWIDTH_MINUS_3:0]}) |
                              (wptr_gray == {rptr_gray_w_sync2[AWIDTH_MINUS_1:AWIDTH_MINUS_2], ~rptr_gray_w_sync2[AWIDTH_MINUS_3:0]});

    // Let me reconsider the full/empty conditions more carefully.
    // For a FIFO with DEPTH = 2^ASIZE entries, we use ASIZE+1 bit pointers.
    // Empty: wptr_gray == rptr_gray
    // Full: wptr_gray == {~rptr_gray[MSB:MSB-1], rptr_gray[MSB-2:0]}

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else if (winc_eff) begin
            wptr <= wptr + 1'b1;
            wptr_gray <= bin2gray(wptr + 1'b1);
        end
    end

    // Synchronize read pointer gray code to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w_sync1 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w_sync1 <= rptr_gray;
            rptr_gray_w_sync2 <= rptr_gray_w_sync1;
        end
    end

    // Read domain logic
    wire rinc_eff = rinc & ~rempty;
    wire rempty_internal;
    wire arempty_internal;

    // Empty condition: wptr_gray == rptr_gray
    assign rempty_internal = (wptr_gray_r_sync2 == rptr_gray);
    
    // Almost empty: one entry away from empty
    assign arempty_internal = (wptr_gray_r_sync2 == rptr_gray) |
                               (wptr_gray_r_sync2 == {rptr_gray[AWIDTH_MINUS_1:AWIDTH_MINUS_2], ~rptr_gray[AWIDTH_MINUS_3:0]});

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else if (rinc_eff) begin
            rptr <= rptr + 1'b1;
            rptr_gray <= bin2gray(rptr + 1'b1);
        end
    end

    // Synchronize write pointer gray code to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r_sync1 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r_sync1 <= wptr_gray;
            wptr_gray_r_sync2 <= wptr_gray_r_sync1;
        end
    end

    // Memory write
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            // No action needed for memory
        end else if (winc_eff) begin
            mem[wptr[ASIZE-1:0]] <= wdata;
        end
    end

    // Memory read
    reg [DSIZE-1:0] rdata_reg;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else if (rinc_eff) begin
            rdata_reg <= mem[rptr[ASIZE-1:0]];
        end
    end

    // Fall-through logic
    // If FALLTHROUGH is "TRUE", rdata should reflect the current head of the FIFO
    // when rempty is false, otherwise it's the registered read data
    wire fallthrough_en = (FALLTHROUGH == "TRUE");
    
    // For fall-through, we need combinational read from memory
    // But the problem says "FALLTHROUGH does not select a combinational memory read"
    // So we always use registered read data
    assign rdata = rdata_reg;

    // Output assignments
    assign wfull = wfull_internal;
    assign awfull = awfull_internal;
    assign rempty = rempty_internal;
    assign arempty = arempty_internal;

endmodule
