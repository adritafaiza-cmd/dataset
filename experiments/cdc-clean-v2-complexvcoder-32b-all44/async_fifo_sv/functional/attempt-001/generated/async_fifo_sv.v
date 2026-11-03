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

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Write and read pointers
    reg [ADDR_WIDTH:0] wptr;
    reg [ADDR_WIDTH:0] rptr;

    // Gray-coded pointers for synchronization
    reg [ADDR_WIDTH:0] wptr_gray_synced;
    reg [ADDR_WIDTH:0] rptr_gray_synced;

    // Binary-coded pointers after synchronization
    wire [ADDR_WIDTH:0] wptr_synced;
    wire [ADDR_WIDTH:0] rptr_synced;

    // Gray code conversion
    function [ADDR_WIDTH:0] gray_encode;
        input [ADDR_WIDTH:0] bin;
        gray_encode = bin ^ (bin >> 1);
    endfunction

    function [ADDR_WIDTH:0] gray_decode;
        input [ADDR_WIDTH:0] gray;
        reg [ADDR_WIDTH:0] bin;
        integer i;
        bin = gray;
        for (i = 1; i <= ADDR_WIDTH; i = i + 1) begin
            bin = bin ^ (gray >> i);
        end
        gray_decode = bin;
    endfunction

    // Write pointer logic
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
        end else if (winc && !wfull) begin
            wptr <= wptr + 1;
        end
    end

    // Read pointer logic
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
        end else if (rinc && !rempty) begin
            rptr <= rptr + 1;
        end
    end

    // Write pointer synchronization
    reg [ADDR_WIDTH:0] wptr_gray;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_synced <= 0;
        end else begin
            wptr_gray_synced <= gray_encode(wptr);
        end
    end

    // Read pointer synchronization
    reg [ADDR_WIDTH:0] rptr_gray;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_synced <= 0;
        end else begin
            rptr_gray_synced <= gray_encode(rptr);
        end
    end

    // Multi-stage synchronizer for write pointer
    genvar i;
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_wptr
            reg [ADDR_WIDTH:0] wptr_gray_stage;
            always @(posedge rclk or negedge rrst_n) begin
                if (!rrst_n) begin
                    wptr_gray_stage <= 0;
                end else begin
                    wptr_gray_stage <= (i == 0) ? wptr_gray_synced : sync_wptr[i-1].wptr_gray_stage;
                end
            end
            assign wptr_gray = (i == SYNC_STAGES - 1) ? wptr_gray_stage : wptr_gray;
        end
    endgenerate

    // Multi-stage synchronizer for read pointer
    generate
        for (i = 0; i < SYNC_STAGES; i = i + 1) begin : sync_rptr
            reg [ADDR_WIDTH:0] rptr_gray_stage;
            always @(posedge wclk or negedge wrst_n) begin
                if (!wrst_n) begin
                    rptr_gray_stage <= 0;
                end else begin
                    rptr_gray_stage <= (i == 0) ? rptr_gray_synced : sync_rptr[i-1].rptr_gray_stage;
                end
            end
            assign rptr_gray = (i == SYNC_STAGES - 1) ? rptr_gray_stage : rptr_gray;
        end
    endgenerate

    // Decode synchronized gray pointers
    assign wptr_synced = gray_decode(wptr_gray);
    assign rptr_synced = gray_decode(rptr_gray);

    // FIFO full and empty flags
    assign wfull = (wptr_synced == {1'b1, rptr_synced[ADDR_WIDTH-1:0]});
    assign rempty = (wptr_synced == rptr_synced);

    // Write data to memory
    always @(posedge wclk) begin
        if (winc && !wfull) begin
            mem[wptr[ADDR_WIDTH-1:0]] <= wdata;
        end
    end

    // Read data from memory
    always @(posedge rclk) begin
        if (rinc && !rempty) begin
            rdata <= mem[rptr[ADDR_WIDTH-1:0]];
        end
    end

    // Debug pointer outputs
    assign waddr = wptr;
    assign raddr = rptr;

endmodule
