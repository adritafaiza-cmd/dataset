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
    localparam FULL_THRESH = DEPTH - 1;
    localparam EMPTY_THRESH = 1;

    // Memory
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Write domain
    reg [AWIDTH-1:0] wptr;
    reg [AWIDTH-1:0] wptr_gray;
    reg [AWIDTH-1:0] rptr_gray_w;
    reg [AWIDTH-1:0] rptr_gray_w_sync1;
    reg [AWIDTH-1:0] rptr_gray_w_sync2;

    // Read domain
    reg [AWIDTH-1:0] rptr;
    reg [AWIDTH-1:0] rptr_gray;
    reg [AWIDTH-1:0] wptr_gray_r;
    reg [AWIDTH-1:0] wptr_gray_r_sync1;
    reg [AWIDTH-1:0] wptr_gray_r_sync2;

    // Gray code conversion
    function [AWIDTH-1:0] bin2gray;
        input [AWIDTH-1:0] bin;
        begin
            bin2gray = bin ^ (bin >> 1);
        end
    endfunction

    function [AWIDTH-1:0] gray2bin;
        input [AWIDTH-1:0] gray;
        reg [AWIDTH-1:0] bin;
        integer i;
        begin
            bin[AWIDTH-1] = gray[AWIDTH-1];
            for (i = AWIDTH-2; i >= 0; i = i - 1)
                bin[i] = gray[i] ^ bin[i+1];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    wire winc_eff = winc & ~wfull;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= {AWIDTH{1'b0}};
            wptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (winc_eff) begin
                wptr <= wptr + 1'b1;
                wptr_gray <= bin2gray(wptr + 1'b1);
            end
        end
    end

    // Synchronize read pointer gray to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w <= {AWIDTH{1'b0}};
            rptr_gray_w_sync1 <= {AWIDTH{1'b0}};
            rptr_gray_w_sync2 <= {AWIDTH{1'b0}};
        end else begin
            rptr_gray_w <= rptr_gray;
            rptr_gray_w_sync1 <= rptr_gray_w;
            rptr_gray_w_sync2 <= rptr_gray_w_sync1;
        end
    end

    // Full and almost full in write domain
    wire [AWIDTH-1:0] rptr_bin_w = gray2bin(rptr_gray_w_sync2);
    wire [AWIDTH-1:0] wptr_minus_rptr = wptr - rptr_bin_w;
    wire wfull = (wptr_minus_rptr == FULL_THRESH);
    wire awfull = (wptr_minus_rptr == FULL_THRESH - 1);

    // Read domain logic
    wire rinc_eff = rinc & ~rempty;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= {AWIDTH{1'b0}};
            rptr_gray <= {AWIDTH{1'b0}};
        end else begin
            if (rinc_eff) begin
                rptr <= rptr + 1'b1;
                rptr_gray <= bin2gray(rptr + 1'b1);
            end
        end
    end

    // Synchronize write pointer gray to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r <= {AWIDTH{1'b0}};
            wptr_gray_r_sync1 <= {AWIDTH{1'b0}};
            wptr_gray_r_sync2 <= {AWIDTH{1'b0}};
        end else begin
            wptr_gray_r <= wptr_gray;
            wptr_gray_r_sync1 <= wptr_gray_r;
            wptr_gray_r_sync2 <= wptr_gray_r_sync1;
        end
    end

    // Empty and almost empty in read domain
    wire [AWIDTH-1:0] wptr_bin_r = gray2bin(wptr_gray_r_sync2);
    wire [AWIDTH-1:0] wptr_minus_rptr_r = wptr_bin_r - rptr;
    wire rempty = (wptr_minus_rptr_r == {AWIDTH{1'b0}});
    wire arempty = (wptr_minus_rptr_r == EMPTY_THRESH);

    // Memory write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read data output
    reg [DSIZE-1:0] rdata_reg;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= {DSIZE{1'b0}};
        end else begin
            if (FALLTHROUGH == "TRUE") begin
                // Fall-through: present data as soon as available
                if (!rempty) begin
                    rdata_reg <= mem[rptr[ASIZE-1:0]];
                end
            end else begin
                // Standard: data available one cycle after read request
                if (rinc_eff) begin
                    rdata_reg <= mem[rptr[ASIZE-1:0]];
                end
            end
        end
    end

    assign rdata = rdata_reg;

endmodule
