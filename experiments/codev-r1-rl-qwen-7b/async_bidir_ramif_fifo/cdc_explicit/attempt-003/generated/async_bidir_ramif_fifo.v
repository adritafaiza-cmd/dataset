module async_bidir_ramif_fifo #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
) (
    // Port A (a_clk domain)
    input wire              a_clk,
    input wire              a_rst_n,
    input wire              a_winc,
    input wire [DSIZE-1:0]  a_wdata,
    input wire              a_rinc,
    output wire [DSIZE-1:0] a_rdata,
    output wire             a_full,
    output wire             a_afull,
    output wire             a_empty,
    output wire             a_aempty,
    input wire              a_dir,
    // Port B (b_clk domain)
    input wire              b_clk,
    input wire              b_rst_n,
    input wire              b_winc,
    input wire [DSIZE-1:0]  b_wdata,
    input wire              b_rinc,
    output wire [DSIZE-1:0] b_rdata,
    output wire             b_full,
    output wire             b_afull,
    output wire             b_empty,
    output wire             b_aempty,
    input wire              b_dir,
    // RAM interface
    output wire             o_ram_a_clk,
    output wire [DSIZE-1:0] o_ram_a_wdata,
    input wire [DSIZE-1:0]  i_ram_a_rdata,
    output wire [ASIZE-1:0] o_ram_a_addr,
    output wire             o_ram_a_rinc,
    output wire             o_ram_a_winc,
    output wire             o_ram_b_clk,
    output wire [DSIZE-1:0] o_ram_b_wdata,
    input wire [DSIZE-1:0]  i_ram_b_rdata,
    output wire [ASIZE-1:0] o_ram_b_addr,
    output wire             o_ram_b_rinc,
    output wire             o_ram_b_winc
);

    localparam ASIZE_PLUS1 = ASIZE + 1;

    // Port A signals (a_clk domain)
    reg [ASIZE_PLUS1-1:0] wptr_a, rptr_b_sync_a;
    reg [ASIZE_PLUS1-1:0] wptr_gray_a;
    reg [ASIZE_PLUS1-1:0] rptr_gray_b_sync_a [1:0];

    // Port B signals (b_clk domain)
    reg [ASIZE_PLUS1-1:0] rptr_b, wptr_a_sync_b [1:0];
    reg [ASIZE_PLUS1-1:0] rptr_gray_b;
    reg [ASIZE_PLUS1-1:0] wptr_gray_a_sync_b [1:0];

    // CDC synchronization
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            wptr_a_sync_b[0] <= 0;
            wptr_a_sync_b[1] <= 0;
        end else begin
            wptr_a_sync_b[0] <= wptr_gray_a;
            wptr_a_sync_b[1] <= wptr_a_sync_b[0];
        end
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            rptr_gray_b_sync_a[0] <= 0;
            rptr_gray_b_sync_a[1] <= 0;
        end else begin
            rptr_gray_b_sync_a[0] <= rptr_gray_b;
            rptr_gray_b_sync_a[1] <= rptr_gray_b_sync_a[0];
        end
    end

    // Port A logic
    wire a_write = a_dir && a_winc;
    wire a_read = !a_dir && a_rinc;

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            wptr_a <= 0;
            wptr_gray_a <= 0;
        end else if (a_write) begin
            wptr_a <= wptr_a + 1;
            wptr_gray_a <= (wptr_a + 1) ^ ((wptr_a + 1) >> 1);
        end
    end

    // Port B logic
    wire b_write = b_dir && b_winc;
    wire b_read = !b_dir && b_rinc;

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            rptr_b <= 0;
            rptr_gray_b <= 0;
        end else if (b_read) begin
            rptr_b <= rptr_b + 1;
            rptr_gray_b <= (rptr_b + 1) ^ ((rptr_b + 1) >> 1);
        end
    end

    // Full/empty flags
    assign a_full = (wptr_a - rptr_gray_b_sync_a[1]) >= (1 << ASIZE);
    assign a_empty = (wptr_a == rptr_gray_b_sync_a[1]);
    assign b_full = (wptr_a_sync_b[1] - rptr_b) >= (1 << ASIZE);
    assign b_empty = (wptr_a_sync_b[1] == rptr_b);

    // RAM interface assignments
    assign o_ram_a_clk = a_clk;
    assign o_ram_a_wdata = a_write ? a_wdata : (b_write ? b_wdata : 0);
    assign o_ram_a_addr = wptr_a[ASIZE-1:0];
    assign o_ram_a_winc = a_write || b_write;
    assign o_ram_a_rinc = a_read;

    assign o_ram_b_clk = b_clk;
    assign o_ram_b_wdata = b_wdata;
    assign o_ram_b_addr = rptr_b[ASIZE-1:0];
    assign o_ram_b_winc = b_write;
    assign o_ram_b_rinc = b_read;

    // Read data
    assign a_rdata = i_ram_a_rdata;
    assign b_rdata = i_ram_b_rdata;

    // Flags (simplified)
    assign a_afull = a_full;
    assign a_aempty = a_empty;
    assign b_afull = b_full;
    assign b_aempty = b_empty;

endmodule
