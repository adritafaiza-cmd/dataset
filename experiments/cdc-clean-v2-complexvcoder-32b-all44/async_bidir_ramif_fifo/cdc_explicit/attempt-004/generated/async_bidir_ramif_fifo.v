module async_bidir_ramif_fifo
  #(
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

    // Internal signals
    reg [ASIZE:0] a_wr_ptr, a_rd_ptr, b_wr_ptr, b_rd_ptr;
    reg [ASIZE:0] a_wr_ptr_sync, a_rd_ptr_sync, b_wr_ptr_sync, b_rd_ptr_sync;
    reg           a_full_reg, a_empty_reg, a_afull_reg, a_aempty_reg;
    reg           b_full_reg, b_empty_reg, b_afull_reg, b_aempty_reg;
    reg [DSIZE-1:0] a_rdata_reg, b_rdata_reg;

    // FIFO depth
    localparam DEPTH = 1 << ASIZE;

    // a_clk domain
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_wr_ptr <= 0;
            a_rd_ptr <= 0;
            a_full_reg <= 0;
            a_empty_reg <= 1;
            a_afull_reg <= 0;
            a_aempty_reg <= 1;
        end else begin
            // Write operations
            if (a_winc && !a_full_reg) begin
                a_wr_ptr <= a_wr_ptr + 1;
            end

            // Read operations
            if (a_rinc && !a_empty_reg) begin
                a_rd_ptr <= a_rd_ptr + 1;
            end

            // Synchronize b pointers
            a_wr_ptr_sync <= b_wr_ptr_sync;
            a_rd_ptr_sync <= b_rd_ptr_sync;

            // Update status flags
            a_full_reg <= (a_wr_ptr[ASIZE:0] == {1'b1, b_rd_ptr_sync[ASIZE-1:0]});
            a_empty_reg <= (a_wr_ptr[ASIZE:0] == a_rd_ptr[ASIZE:0]);
            a_afull_reg <= (a_wr_ptr[ASIZE:0] == {b_rd_ptr_sync[ASIZE-1:0], 1'b1});
            a_aempty_reg <= (a_wr_ptr[ASIZE:0] == {a_rd_ptr[ASIZE:0], 1'b1});
        end
    end

    // b_clk domain
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_wr_ptr <= 0;
            b_rd_ptr <= 0;
            b_full_reg <= 0;
            b_empty_reg <= 1;
            b_afull_reg <= 0;
            b_aempty_reg <= 1;
        end else begin
            // Write operations
            if (b_winc && !b_full_reg) begin
                b_wr_ptr <= b_wr_ptr + 1;
            end

            // Read operations
            if (b_rinc && !b_empty_reg) begin
                b_rd_ptr <= b_rd_ptr + 1;
            end

            // Synchronize a pointers
            b_wr_ptr_sync <= a_wr_ptr_sync;
            b_rd_ptr_sync <= a_rd_ptr_sync;

            // Update status flags
            b_full_reg <= (b_wr_ptr[ASIZE:0] == {1'b1, a_rd_ptr_sync[ASIZE-1:0]});
            b_empty_reg <= (b_wr_ptr[ASIZE:0] == b_rd_ptr[ASIZE:0]);
            b_afull_reg <= (b_wr_ptr[ASIZE:0] == {a_rd_ptr_sync[ASIZE-1:0], 1'b1});
            b_aempty_reg <= (b_wr_ptr[ASIZE:0] == {b_rd_ptr[ASIZE:0], 1'b1});
        end
    end

    // a_clk domain RAM interface
    always @(posedge a_clk) begin
        o_ram_a_clk <= a_clk;
        o_ram_a_wdata <= a_wdata;
        o_ram_a_addr <= a_wr_ptr[ASIZE-1:0];
        o_ram_a_winc <= a_winc && !a_full_reg;
        o_ram_a_rinc <= a_rinc && !a_empty_reg;
    end

    // b_clk domain RAM interface
    always @(posedge b_clk) begin
        o_ram_b_clk <= b_clk;
        o_ram_b_wdata <= b_wdata;
        o_ram_b_addr <= b_wr_ptr[ASIZE-1:0];
        o_ram_b_winc <= b_winc && !b_full_reg;
        o_ram_b_rinc <= b_rinc && !b_empty_reg;
    end

    // a_clk domain read data
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata_reg <= 0;
        end else if (a_rinc && !a_empty_reg) begin
            a_rdata_reg <= i_ram_a_rdata;
        end
    end

    // b_clk domain read data
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata_reg <= 0;
        end else if (b_rinc && !b_empty_reg) begin
            b_rdata_reg <= i_ram_b_rdata;
        end
    end

    // Output assignments
    assign a_rdata = a_rdata_reg;
    assign a_full = a_full_reg;
    assign a_afull = a_afull_reg;
    assign a_empty = a_empty_reg;
    assign a_aempty = a_aempty_reg;

    assign b_rdata = b_rdata_reg;
    assign b_full = b_full_reg;
    assign b_afull = b_afull_reg;
    assign b_empty = b_empty_reg;
    assign b_aempty = b_aempty_reg;

endmodule
