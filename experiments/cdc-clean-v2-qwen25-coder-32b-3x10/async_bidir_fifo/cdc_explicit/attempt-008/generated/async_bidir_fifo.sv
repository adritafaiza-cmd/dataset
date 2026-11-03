module async_bidir_fifo
  #(
    parameter DSIZE         = 8,
    parameter ASIZE         = 4,
    parameter FALLTHROUGH   = "TRUE"
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
       input wire              b_dir
       );

    localparam DEPTH = 1 << ASIZE;
    localparam AFULL_THRESHOLD = DEPTH - 2;
    localparam AEMPTY_THRESHOLD = 1;

    // FIFO for A to B direction
    reg [DSIZE-1:0] mem_a2b [0:DEPTH-1];
    reg [ASIZE:0] wr_ptr_a2b, rd_ptr_a2b;
    reg [ASIZE:0] wr_ptr_a2b_sync, rd_ptr_a2b_sync;

    // FIFO for B to A direction
    reg [DSIZE-1:0] mem_b2a [0:DEPTH-1];
    reg [ASIZE:0] wr_ptr_b2a, rd_ptr_b2a;
    reg [ASIZE:0] wr_ptr_b2a_sync, rd_ptr_b2a_sync;

    // Synchronization for A to B pointers
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            wr_ptr_a2b_sync <= 0;
            rd_ptr_a2b_sync <= 0;
        end else begin
            wr_ptr_a2b_sync <= wr_ptr_a2b;
            rd_ptr_a2b_sync <= rd_ptr_a2b_sync + 1;
        end
    end

    // Synchronization for B to A pointers
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            wr_ptr_b2a_sync <= 0;
            rd_ptr_b2a_sync <= 0;
        end else begin
            wr_ptr_b2a_sync <= wr_ptr_b2a;
            rd_ptr_b2a_sync <= rd_ptr_b2a_sync + 1;
        end
    end

    // Write and read logic for A to B FIFO
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            wr_ptr_a2b <= 0;
            rd_ptr_a2b <= 0;
        end else begin
            if (a_dir && !a_full) begin
                mem_a2b[wr_ptr_a2b[ASIZE-1:0]] <= a_wdata;
                wr_ptr_a2b <= wr_ptr_a2b + 1;
            end
            if (a_rinc && !a_empty) begin
                rd_ptr_a2b <= rd_ptr_a2b + 1;
            end
        end
    end

    // Write and read logic for B to A FIFO
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            wr_ptr_b2a <= 0;
            rd_ptr_b2a <= 0;
        end else begin
            if (b_dir && !b_full) begin
                mem_b2a[wr_ptr_b2a[ASIZE-1:0]] <= b_wdata;
                wr_ptr_b2a <= wr_ptr_b2a + 1;
            end
            if (b_rinc && !b_empty) begin
                rd_ptr_b2a <= rd_ptr_b2a + 1;
            end
        end
    end

    // Flags for A to B FIFO
    assign a_full = (wr_ptr_a2b[ASIZE:0] == {wr_ptr_a2b_sync[ASIZE], rd_ptr_a2b_sync[ASIZE-1:0]});
    assign a_empty = (wr_ptr_a2b_sync[ASIZE:0] == {rd_ptr_a2b[ASIZE], rd_ptr_a2b[ASIZE-1:0]});
    assign a_afull = (wr_ptr_a2b[ASIZE:0] == {wr_ptr_a2b_sync[ASIZE], rd_ptr_a2b_sync[ASIZE-1:0] - AFULL_THRESHOLD});
    assign a_aempty = (wr_ptr_a2b_sync[ASIZE:0] == {rd_ptr_a2b[ASIZE], rd_ptr_a2b[ASIZE-1:0] + AEMPTY_THRESHOLD});

    // Flags for B to A FIFO
    assign b_full = (wr_ptr_b2a[ASIZE:0] == {wr_ptr_b2a_sync[ASIZE], rd_ptr_b2a_sync[ASIZE-1:0]});
    assign b_empty = (wr_ptr_b2a_sync[ASIZE:0] == {rd_ptr_b2a[ASIZE], rd_ptr_b2a[ASIZE-1:0]});
    assign b_afull = (wr_ptr_b2a[ASIZE:0] == {wr_ptr_b2a_sync[ASIZE], rd_ptr_b2a_sync[ASIZE-1:0] - AFULL_THRESHOLD});
    assign b_aempty = (wr_ptr_b2a_sync[ASIZE:0] == {rd_ptr_b2a[ASIZE], rd_ptr_b2a[ASIZE-1:0] + AEMPTY_THRESHOLD});

    // Read data for A to B FIFO
    always @(posedge a_clk or negedge a_rst_n) begin
        if (!a_rst_n) begin
            a_rdata <= 0;
        end else if (a_rinc && !a_empty) begin
            a_rdata <= mem_a2b[rd_ptr_a2b[ASIZE-1:0]];
        end
    end

    // Read data for B to A FIFO
    always @(posedge b_clk or negedge b_rst_n) begin
        if (!b_rst_n) begin
            b_rdata <= 0;
        end else if (b_rinc && !b_empty) begin
            b_rdata <= mem_b2a[rd_ptr_b2a[ASIZE-1:0]];
        end
    end

endmodule
