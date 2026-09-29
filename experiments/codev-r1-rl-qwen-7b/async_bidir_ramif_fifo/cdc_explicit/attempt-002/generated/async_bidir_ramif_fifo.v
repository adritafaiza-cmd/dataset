module async_bidir_ramif_fifo #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "FALSE"
) (
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

    // FIFO A side (a_clk domain)
    reg [ASIZE:0] a_wptr, a_rptr;
    wire [ASIZE:0] a_wptr_gray = a_wptr ^ (a_wptr >> 1);
    wire [ASIZE:0] a_rptr_gray = a_rptr ^ (a_rptr >> 1);

    // Synchronize a_rptr to b_clk domain
    reg [ASIZE:0] a_rptr_sync_b [2:0];
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_rptr_sync_b[0] <= 0;
            a_rptr_sync_b[1] <= 0;
            a_rptr_sync_b[2] <= 0;
        end else begin
            a_rptr_sync_b[0] <= a_rptr_gray;
            a_rptr_sync_b[1] <= a_rptr_sync_b[0];
            a_rptr_sync_b[2] <= a_rptr_sync_b[1];
        end
    end

    // Synchronize a_wptr to b_clk domain
    reg [ASIZE:0] a_wptr_sync_b [2:0];
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            a_wptr_sync_b[0] <= 0;
            a_wptr_sync_b[1] <= 0;
            a_wptr_sync_b[2] <= 0;
        end else begin
            a_wptr_sync_b[0] <= a_wptr_gray;
            a_wptr_sync_b[1] <= a_wptr_sync_b[0];
            a_wptr_sync_b[2] <= a_wptr_sync_b[1];
        end
    end

    // FIFO B side (b_clk domain)
    reg [ASIZE:0] b_wptr, b_rptr;
    wire [ASIZE:0] b_wptr_gray = b_wptr ^ (b_wptr >> 1);
    wire [ASIZE:0] b_rptr_gray = b_rptr ^ (b_rptr >> 1);

    // Synchronize b_rptr to a_clk domain
    reg [ASIZE:0] b_rptr_sync_a [2:0];
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_rptr_sync_a[0] <= 0;
            b_rptr_sync_a[1] <= 0;
            b_rptr_sync_a[2] <= 0;
        end else begin
            b_rptr_sync_a[0] <= b_rptr_gray;
            b_rptr_sync_a[1] <= b_rptr_sync_a[0];
            b_rptr_sync_a[2] <= b_rptr_sync_a[1];
        end
    end

    // Synchronize b_wptr to a_clk domain
    reg [ASIZE:0] b_wptr_sync_a [2:0];
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            b_wptr_sync_a[0] <= 0;
            b_wptr_sync_a[1] <= 0;
            b_wptr_sync_a[2] <= 0;
        end else begin
            b_wptr_sync_a[0] <= b_wptr_gray;
            b_wptr_sync_a[1] <= b_wptr_sync_a[0];
            b_wptr_sync_a[2] <= b_wptr_sync_a[1];
        end
    end

    // A side logic
    wire a_write_en = a_dir & a_winc;
    wire a_read_en = ~a_dir & a_rinc;

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wptr <= 0;
            a_rptr <= 0;
        end else begin
            if (a_write_en) a_wptr <= a_wptr + 1;
            if (a_read_en) a_rptr <= a_rptr + 1;
        end
    end

    assign a_full = (a_wptr[ASIZE] != a_rptr_sync_b[2][ASIZE]) && 
                    (a_wptr[ASIZE-1:0] == a_rptr_sync_b[2][ASIZE-1:0]);
    assign a_empty = (a_wptr == a_rptr_sync_b[2]);

    assign a_afull = a_full;
    assign a_aempty = a_empty;

    assign o_ram_a_clk = a_clk;
    assign o_ram_a_wdata = a_wdata;
    assign o_ram_a_addr = a_wptr[ASIZE-1:0];
    assign o_ram_a_winc = a_write_en;
    assign o_ram_a_rinc = a_read_en;

    assign a_rdata = i_ram_a_rdata;

    // B side logic
    wire b_write_en = b_dir & b_winc;
    wire b_read_en = ~b_dir & b_rinc;

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wptr <= 0;
            b_rptr <= 0;
        end else begin
            if (b_write_en) b_wptr <= b_wptr + 1;
            if (b_read_en) b_rptr <= b_rptr + 1;
        end
    end

    assign b_full = (b_wptr[ASIZE] != b_rptr_sync_a[2][ASIZE]) && 
                    (b_wptr[ASIZE-1:0] == b_rptr_sync_a[2][ASIZE-1:0]);
    assign b_empty = (b_wptr == b_rptr_sync_a[2]);

    assign b_afull = b_full;
    assign b_aempty = b_empty;

    assign o_ram_b_clk = b_clk;
    assign o_ram_b_wdata = b_wdata;
    assign o_ram_b_addr = b_wptr[ASIZE-1:0];
    assign o_ram_b_winc = b_write_en;
    assign o_ram_b_rinc = b_read_en;

    assign b_rdata = i_ram_b_rdata;

endmodule
