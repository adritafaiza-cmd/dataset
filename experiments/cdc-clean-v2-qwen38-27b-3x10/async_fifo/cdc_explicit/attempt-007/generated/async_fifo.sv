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
    localparam AWFULL_THRESH = DEPTH - 4;
    localparam AEMPTY_THRESH = 4;

    // Write domain
    reg [ASIZE:0] wptr;
    reg [ASIZE:0] rptr_w;
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    wire wfull_int = (wptr[ASIZE] != rptr_w[ASIZE]) && (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]);
    wire awfull_int = (wptr[ASIZE-1:0] - rptr_w[ASIZE-1:0] >= AWFULL_THRESH[ASIZE-1:0]);

    wire winc_eff = winc && !wfull_int;

    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            wptr <= 0;
            rptr_w <= 0;
        end else begin
            if (winc_eff)
                wptr <= wptr + 1;
            if (rinc_sync_w)
                rptr_w <= rptr_w + 1;
        end
    end

    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read domain
    reg [ASIZE:0] rptr;
    reg [ASIZE:0] wptr_r;
    reg [DSIZE-1:0] rdata_reg;
    reg rdata_valid;

    wire rempty_int = (rptr == wptr_r);
    wire arempty_int = (wptr_r[ASIZE-1:0] - rptr[ASIZE-1:0] <= AEMPTY_THRESH[ASIZE-1:0]);

    wire rinc_eff = rinc && !rempty_int;

    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rptr <= 0;
            wptr_r <= 0;
            rdata_reg <= 0;
            rdata_valid <= 0;
        end else begin
            if (winc_sync_r)
                wptr_r <= winc_sync_r ? wptr_r + 1 : wptr_r;
            if (rinc_eff)
                rptr <= rptr + 1;
            // Data transfer: when a write is acknowledged in read domain,
            // capture the data at the write pointer position
            if (winc_sync_r)
                rdata_reg <= mem[wptr_r[ASIZE-1:0]];
            // Valid tracking
            if (winc_sync_r && !rinc_eff)
                rdata_valid <= 1;
            else if (rinc_eff && !winc_sync_r)
                rdata_valid <= 0;
            else if (winc_sync_r && rinc_eff)
                rdata_valid <= rdata_valid; // stays same
            else
                rdata_valid <= rdata_valid;
        end
    end

    // CDC: winc from write to read domain
    reg winc_sync1, winc_sync2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            winc_sync1 <= 0;
            winc_sync2 <= 0;
        end else begin
            winc_sync1 <= winc_eff;
            winc_sync2 <= winc_sync1;
        end
    end
    wire winc_sync_r = winc_sync2;

    // CDC: rinc from read to write domain
    reg rinc_sync1, rinc_sync2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rinc_sync1 <= 0;
            rinc_sync2 <= 0;
        end else begin
            rinc_sync1 <= rinc_eff;
            rinc_sync2 <= rinc_sync1;
        end
    end
    wire rinc_sync_w = rinc_sync2;

    // CDC: wptr from write to read domain (gray code)
    wire [ASIZE:0] wptr_gray = wptr ^ (wptr >> 1);
    reg [ASIZE:0] wptr_gray_r1, wptr_gray_r2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= 0;
            wptr_gray_r2 <= 0;
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end
    wire [ASIZE:0] wptr_r_gray = wptr_gray_r2;
    wire [ASIZE:0] wptr_r_bin = gray2bin(wptr_r_gray);

    // CDC: rptr from read to write domain (gray code)
    wire [ASIZE:0] rptr_gray = rptr ^ (rptr >> 1);
    reg [ASIZE:0] rptr_gray_w1, rptr_gray_w2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= 0;
            rptr_gray_w2 <= 0;
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end
    wire [ASIZE:0] rptr_w_gray = rptr_gray_w2;
    wire [ASIZE:0] rptr_w_bin = gray2bin(rptr_w_gray);

    // Override the earlier rptr_w and wptr_r with the properly synchronized versions
    // Actually, let me restructure: use the gray-coded synchronized pointers directly

    // Let me redo this more carefully. The issue is that I declared rptr_w and wptr_r as regs
    // but they should be derived from the gray code synchronization. Let me use wires instead.

    // Actually, I need to restructure. Let me use the synchronized binary pointers.

    // The wptr_r used in read domain should be wptr_r_bin
    // The rptr_w used in write domain should be rptr_w_bin

    // But I already declared them as regs. Let me fix by making them wires.

    // I'll restructure the whole thing properly.

endmodule

function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    begin
        gray2bin[ASIZE] = gray[ASIZE];
        for (i = ASIZE-1; i >= 0; i = i - 1)
            gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
endfunction

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
    localparam AWFULL_THRESH = DEPTH - 4;
    localparam AEMPTY_THRESH = 4;

    // Write domain registers
    reg [ASIZE:0] wptr;
    reg [DSIZE-1:0] mem [0:DEPTH-1];

    // Read domain registers
    reg [ASIZE:0] rptr;
    reg [DSIZE-1:0] rdata_reg;
    reg rdata_valid;

    // Gray code pointers for CDC
    wire [ASIZE:0] wptr_gray = wptr ^ (wptr >> 1);
    wire [ASIZE:0] rptr_gray = rptr ^ (rptr >> 1);

    // Synchronize wptr_gray to read domain
    reg [ASIZE:0] wptr_gray_r1, wptr_gray_r2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            wptr_gray_r1 <= 0;
            wptr_gray_r2 <= 0;
        end else begin
            wptr_gray_r1 <= wptr_gray;
            wptr_gray_r2 <= wptr_gray_r1;
        end
    end
    wire [ASIZE:0] wptr_r = gray2bin(wptr_gray_r2);

    // Synchronize rptr_gray to write domain
    reg [ASIZE:0] rptr_gray_w1, rptr_gray_w2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rptr_gray_w1 <= 0;
            rptr_gray_w2 <= 0;
        end else begin
            rptr_gray_w1 <= rptr_gray;
            rptr_gray_w2 <= rptr_gray_w1;
        end
    end
    wire [ASIZE:0] rptr_w = gray2bin(rptr_gray_w2);

    // Write domain status
    wire wfull_int = (wptr[ASIZE] != rptr_w[ASIZE]) && (wptr[ASIZE-1:0] == rptr_w[ASIZE-1:0]);
    wire awfull_int = (wptr[ASIZE-1:0] - rptr_w[ASIZE-1:0] >= AWFULL_THRESH[ASIZE-1:0]);
    wire winc_eff = winc && !wfull_int;

    // Read domain status
    wire rempty_int = (rptr == wptr_r);
    wire arempty_int = (wptr_r[ASIZE-1:0] - rptr[ASIZE-1:0] <= AEMPTY_THRESH[ASIZE-1:0]);
    wire rinc_eff = rinc && !rempty_int;

    // Synchronize winc_eff to read domain
    reg winc_sync1, winc_sync2;
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            winc_sync1 <= 0;
            winc_sync2 <= 0;
        end else begin
            winc_sync1 <= winc_eff;
            winc_sync2 <= winc_sync1;
        end
    end
    wire winc_sync_r = winc_sync2;

    // Synchronize rinc_eff to write domain
    reg rinc_sync1, rinc_sync2;
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n) begin
            rinc_sync1 <= 0;
            rinc_sync2 <= 0;
        end else begin
            rinc_sync1 <= rinc_eff;
            rinc_sync2 <= rinc_sync1;
        end
    end
    wire rinc_sync_w = rinc_sync2;

    // Write pointer update
    always @(posedge wclk or negedge wrst_n) begin
        if (!wrst_n)
            wptr <= 0;
        else if (winc_eff)
            wptr <= wptr + 1;
    end

    // Memory write
    always @(posedge wclk) begin
        if (winc_eff)
            mem[wptr[ASIZE-1:0]] <= wdata;
    end

    // Read pointer update
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n)
            rptr <= 0;
        else if (rinc_eff)
            rptr <= rptr + 1;
    end

    // Data capture in read domain: when a write is acknowledged, capture data
    always @(posedge rclk or negedge rrst_n) begin
        if (!rrst_n) begin
            rdata_reg <= 0;
            rdata_valid <= 0;
        end else begin
            if (winc_sync_r)
                rdata_reg <= mem[wptr_r[ASIZE-1:0]];
            if (winc_sync_r && !rinc_eff)
                rdata_valid <= 1;
            else if (rinc_eff && !winc_sync_r)
                rdata_valid <= 0;
            else
                rdata_valid <= rdata_valid;
        end
    end

    // Outputs
    assign wfull = wfull_int;
    assign awfull = awfull_int;
    assign rempty = rempty_int;
    assign arempty = arempty_int;
    assign rdata = rdata_reg;

endmodule

function [ASIZE:0] gray2bin;
    input [ASIZE:0] gray;
    integer i;
    begin
        gray2bin[ASIZE] = gray[ASIZE];
        for (i = ASIZE-1; i >= 0; i = i - 1)
            gray2bin[i] = gray[i] ^ gray2bin[i+1];
    end
endfunction
