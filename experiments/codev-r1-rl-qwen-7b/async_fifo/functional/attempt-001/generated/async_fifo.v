module async_fifo #(
    parameter DSIZE = 8,
    parameter ASIZE = 4,
    parameter FALLTHROUGH = "TRUE"
) (
    input wire wclk,
    input wire wrst_n,
    input wire winc,
    input wire [DSIZE-1:0] wdata,
    output wire wfull,
    output wire awfull,
    input wire rclk,
    input wire rrst_n,
    input wire rinc,
    output wire [DSIZE-1:0] rdata,
    output wire rempty,
    output wire arempty
);

    localparam FIFO_DEPTH = 1 << ASIZE;

    // Write domain signals
    reg [ASIZE:0] wptr_bin;
    reg [ASIZE:0] rptr_gray_sync1, rptr_gray_sync2;

    // Read domain signals
    reg [ASIZE:0] rptr_bin;
    reg [ASIZE:0] wptr_gray_sync1, wptr_gray_sync2;

    // FIFO memory
    reg [DSIZE-1:0] mem [0:FIFO_DEPTH-1];

    // Gray code functions
    function [ASIZE:0] bin2gray(input [ASIZE:0] bin);
        bin2gray = bin ^ (bin >> 1);
    endfunction

    function [ASIZE:0] gray2bin(input [ASIZE:0] gray);
        reg [ASIZE:0] bin;
        integer i;
        begin
            bin[ASIZE] = gray[ASIZE];
            for (i = ASIZE-1; i >= 0; i = i - 1)
                bin[i] = bin[i+1] ^ gray[i];
            gray2bin = bin;
        end
    endfunction

    // Write domain logic
    wire [ASIZE:0] rptr_bin_sync = gray2bin(rptr_gray_sync2);
    wire [ASIZE:0] wgray_next = bin2gray(wptr_bin + 1'b1);
    wire full = (wgray_next == { ~rptr_gray_sync2[ASIZE:ASIZE-1], rptr_gray_sync2[ASIZE-2:0] });

    wire [ASIZE:0] wdiff = wptr_bin - rptr_bin_sync;
    assign awfull = (wdiff >= (FIFO_DEPTH - 1));

    // Update write pointer
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr_bin <= 0;
        else if (winc && !full)
            wptr_bin <= wptr_bin + 1;
    end

    // Write data
    always @(posedge wclk) begin
        if (winc && !full)
            mem[wptr_bin[ASIZE-1:0]] <= wdata;
    end

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync1 <= 0;
            rptr_gray_sync2 <= 0;
        end else begin
            rptr_gray_sync1 <= rptr_gray;
            rptr_gray_sync2 <= rptr_gray_sync1;
        end
    end

    // Read domain logic
    wire [ASIZE:0] wptr_bin_sync = gray2bin(wptr_gray_sync2);
    wire [ASIZE:0] rgray_next = bin2gray(rptr_bin + 1'b1);
    wire empty = (rptr_bin == wptr_bin_sync);

    wire [ASIZE:0] rdiff = rptr_bin - wptr_bin_sync;
    assign arempty = (rdiff <= 1);

    // Update read pointer
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr_bin <= 0;
        else if (rinc && !empty)
            rptr_bin <= rptr_bin + 1;
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync1 <= 0;
            wptr_gray_sync2 <= 0;
        end else begin
            wptr_gray_sync1 <= wptr_gray;
            wptr_gray_sync2 <= wptr_gray_sync1;
        end
    end

    // Read data
    generate
        if (FALLTHROUGH == "TRUE") begin
            assign rdata = mem[rptr_bin[ASIZE-1:0]];
        end else begin
            reg [DSIZE-1:0] rdata_reg;
            always @(posedge rclk) begin
                if (rinc && !empty)
                    rdata_reg <= mem[rptr_bin[ASIZE-1:0]];
            end
            assign rdata = rdata_reg;
        end
    endgenerate

    // Assign outputs
    assign wfull = full;
    assign rempty = empty;

endmodule
