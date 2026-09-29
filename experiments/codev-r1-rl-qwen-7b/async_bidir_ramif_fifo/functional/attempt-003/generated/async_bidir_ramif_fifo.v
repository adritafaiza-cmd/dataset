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

    // FIFO a_to_b: a writes to port A, b reads from port A
    reg [ASIZE:0] a_to_b_wptr, a_to_b_rptr;
    wire a_to_b_full = (a_to_b_wptr[ASIZE] != a_to_b_rptr[ASIZE]) && 
                       (a_to_b_wptr[ASIZE-1:0] == a_to_b_rptr[ASIZE-1:0]);
    wire a_to_b_empty = (a_to_b_wptr == a_to_b_rptr);

    // FIFO b_to_a: b writes to port B, a reads from port B
    reg [ASIZE:0] b_to_a_wptr, b_to_a_rptr;
    wire b_to_a_full = (b_to_a_wptr[ASIZE] != b_to_a_rptr[ASIZE]) && 
                       (b_to_a_wptr[ASIZE-1:0] == b_to_a_rptr[ASIZE-1:0]);
    wire b_to_a_empty = (b_to_a_wptr == b_to_a_rptr);

    // a_to_b FIFO pointers
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) a_to_b_wptr <= 0;
        else if (a_dir && a_winc && !a_to_b_full)
            a_to_b_wptr <= a_to_b_wptr + 1;
    end

    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) a_to_b_rptr <= 0;
        else if (!a_dir && b_rinc && !a_to_b_empty)
            a_to_b_rptr <= a_to_b_rptr + 1;
    end

    // b_to_a FIFO pointers
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) b_to_a_wptr <= 0;
        else if (b_dir && b_winc && !b_to_a_full)
            b_to_a_wptr <= b_to_a_wptr + 1;
    end

    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) b_to_a_rptr <= 0;
        else if (!b_dir && a_rinc && !b_to_a_empty)
            b_to_a_rptr <= b_to_a_rptr + 1;
    end

    // Output assignments
    assign o_ram_a_clk = a_clk;
    assign o_ram_a_wdata = a_wdata;
    assign o_ram_a_addr = a_to_b_wptr[ASIZE-1:0];
    assign o_ram_a_winc = a_dir && a_winc && !a_to_b_full;
    assign o_ram_a_rinc = 0; // Not used in this implementation

    assign o_ram_b_clk = b_clk;
    assign o_ram_b_wdata = b_wdata;
    assign o_ram_b_addr = b_to_a_wptr[ASIZE-1:0];
    assign o_ram_b_winc = b_dir && b_winc && !b_to_a_full;
    assign o_ram_b_rinc = 0; // Not used in this implementation

    // Read data assignments
    assign a_rdata = i_ram_b_rdata;
    assign b_rdata = i_ram_a_rdata;

    // Flags
    assign a_full = a_to_b_full;
    assign a_empty = a_to_b_empty;
    assign b_full = b_to_a_full;
    assign b_empty = b_to_a_empty;

    // Almost full/empty
    wire [ASIZE:0] a_to_b_diff = a_to_b_wptr - a_to_b_rptr;
    wire [ASIZE:0] b_to_a_diff = b_to_a_wptr - b_to_a_rptr;

    generate
        if (FALLTHROUGH == "TRUE") begin
            assign a_afull = (a_to_b_diff >= (ASIZE-1));
            assign a_aempty = (a_to_b_diff <= 1);
            assign b_afull = (b_to_a_diff >= (ASIZE-1));
            assign b_aempty = (b_to_a_diff <= 1);
        end else begin
            assign a_afull = (a_to_b_diff >= ASIZE);
            assign a_aempty = (a_to_b_diff <= 0);
            assign b_afull = (b_to_a_diff >= ASIZE);
            assign b_aempty = (b_to_a_diff <= 0);
        end
    endgenerate

endmodule
