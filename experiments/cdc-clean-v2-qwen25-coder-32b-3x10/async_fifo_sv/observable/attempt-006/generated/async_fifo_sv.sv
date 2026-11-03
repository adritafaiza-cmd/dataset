module async_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter SYNC_STAGES = 2
)(
    input  wire                    wclk,
    input  wire                    wrst_n,
    input  wire                    winc,
    input  wire [DATA_WIDTH-1:0]   wdata,
    output wire                    wfull,
    output wire [ADDR_WIDTH:0]     waddr,
    input  wire                    rclk,
    input  wire                    rrst_n,
    input  wire                    rinc,
    output wire [DATA_WIDTH-1:0]   rdata,
    output wire                    rempty,
    output wire [ADDR_WIDTH:0]     raddr
);

    localparam DEPTH = 2**ADDR_WIDTH;
    localparam AW = ADDR_WIDTH + 1;

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [AW-1:0] wptr, rptr;
    reg [AW-1:0] wptr_gray, rptr_gray;
    reg [AW-1:0] rptr_gray_sync [0:SYNC_STAGES-1];
    reg [AW-1:0] wptr_gray_sync [0:SYNC_STAGES-1];

    // Binary to Gray conversion
    function [AW-1:0] bin_to_gray;
        input [AW-1:0] bin;
        bin_to_gray = bin ^ (bin >> 1);
    endfunction

    // Gray to Binary conversion
    function [AW-1:0] gray_to_bin;
        input [AW-1:0] gray;
        integer i;
        reg [AW-1:0] bin;
        bin = gray;
        for (i = AW-2; i >= 0; i = i - 1) begin
            bin[i] = bin[i+1] ^ gray[i];
        end
        gray_to_bin = bin;
    endfunction

    // Write side logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            wptr_gray <= 0;
        end else if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
            wptr <= wptr + 1;
            wptr_gray <= bin_to_gray(wptr + 1);
        end
    end

    // Read side logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            rptr_gray <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
            rptr_gray <= bin_to_gray(rptr + 1);
        end
    end

    // Synchronize write pointer to read domain
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_sync[0] <= 0;
        end else begin
            wptr_gray_sync[0] <= wptr_gray;
        end
    end

    genvar i;
    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    wptr_gray_sync[i] <= 0;
                end else begin
                    wptr_gray_sync[i] <= wptr_gray_sync[i-1];
                end
            end
        end
    endgenerate

    // Synchronize read pointer to write domain
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_sync[0] <= 0;
        end else begin
            rptr_gray_sync[0] <= rptr_gray;
        end
    end

    generate
        for (i = 1; i < SYNC_STAGES; i = i + 1) begin : sync_stages_w
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    rptr_gray_sync[i] <= 0;
                end else begin
                    rptr_gray_sync[i] <= rptr_gray_sync[i-1];
                end
            end
        end
    endgenerate

    // Calculate full and empty flags
    wire [AW-1:0] wptr_gray_sync_final = wptr_gray_sync[SYNC_STAGES-1];
    wire [AW-1:0] rptr_gray_sync_final = rptr_gray_sync[SYNC_STAGES-1];
    wire [AW-1:0] wptr_sync = gray_to_bin(wptr_gray_sync_final);
    wire [AW-1:0] rptr_sync = gray_to_bin(rptr_gray_sync_final);

    assign wfull = (wptr_sync[ADDR_WIDTH:ADDR_WIDTH-1] != rptr_sync[ADDR_WIDTH:ADDR_WIDTH-1]) && (wptr_sync[ADDR_WIDTH-1:0] == rptr_sync[ADDR_WIDTH-1:0]);
    assign rempty = (wptr_sync[ADDR_WIDTH:ADDR_WIDTH-1] == rptr_sync[ADDR_WIDTH:ADDR_WIDTH-1]) && (wptr_sync[ADDR_WIDTH-1:0] == rptr_sync[ADDR_WIDTH-1:0]);

    // Output read data and address
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata <= 0;
        end else if (rinc && !rempty) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    assign waddr = wptr;
    assign raddr = rptr;

endmodule
