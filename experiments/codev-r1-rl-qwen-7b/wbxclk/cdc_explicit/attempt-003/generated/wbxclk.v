module wbxclk #(
    parameter AW = 32,
    DW = 32,
    LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [AW-1:0] i_wb_addr,
    input wire [DW-1:0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [DW-1:0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [AW-1:0] o_xclk_addr,
    output reg [DW-1:0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [DW-1:0] i_xclk_data,
    input wire i_xclk_err
);

localparam FIFO_DEPTH = 2 ** LGFIFO;
localparam FIFO_ADDR_WIDTH = LGFIFO;
localparam FIFO_DATA_WIDTH = 1 + 1 + 1 + AW + DW + (DW/8);

// FIFO signals
reg [FIFO_DATA_WIDTH-1:0] fifo [0:FIFO_DEPTH-1];
reg [FIFO_ADDR_WIDTH:0] wr_ptr, rd_ptr;
reg [FIFO_ADDR_WIDTH:0] wr_ptr_gray, rd_ptr_gray;
reg fifo_full, fifo_empty;

// Write side (i_wb_clk domain)
wire write_enable = i_wb_cyc && i_wb_stb && !o_wb_stall;

// Read side (i_xclk_clk domain)
wire read_enable = i_xclk_ack && !i_xclk_stall;

// o_wb_stall is high when FIFO is full
assign o_wb_stall = fifo_full;

// FIFO write logic
always @(posedge i_wb_clk or posedge i_reset) begin
    if (i_reset) begin
        wr_ptr <= 0;
        wr_ptr_gray <= 0;
        fifo_full <= 0;
        fifo_empty <= 1;
    end else begin
        if (write_enable && !fifo_full) begin
            fifo[wr_ptr[FIFO_ADDR_WIDTH-1:0]] <= {i_wb_cyc, i_wb_stb, i_wb_we, i_wb_addr, i_wb_data, i_wb_sel};
            wr_ptr <= wr_ptr + 1;
            wr_ptr_gray <= (wr_ptr >> 1) ^ wr_ptr;
        end
        // Update full condition
        fifo_full <= ((wr_ptr_gray == rd_ptr_gray) && (wr_ptr[FIFO_ADDR_WIDTH] != rd_ptr[FIFO_ADDR_WIDTH]));
    end
end

// FIFO read logic (i_xclk_clk domain)
always @(posedge i_xclk_clk or posedge i_reset) begin
    if (i_reset) begin
        rd_ptr <= 0;
        rd_ptr_gray <= 0;
        fifo_empty <= 1;
        o_xclk_cyc <= 0;
        o_xclk_stb <= 0;
        o_xclk_we <= 0;
        o_xclk_addr <= 0;
        o_xclk_data <= 0;
        o_xclk_sel <= 0;
    end else begin
        if (read_enable && !fifo_empty) begin
            {o_xclk_cyc, o_xclk_stb, o_xclk_we, o_xclk_addr, o_xclk_data, o_xclk_sel} <= fifo[rd_ptr[FIFO_ADDR_WIDTH-1:0]];
            rd_ptr <= rd_ptr + 1;
            rd_ptr_gray <= (rd_ptr >> 1) ^ rd_ptr;
            fifo_empty <= 0;
        end
        // Update empty condition
        fifo_empty <= ((rd_ptr_gray == wr_ptr_gray) && (rd_ptr[FIFO_ADDR_WIDTH] != wr_ptr[FIFO_ADDR_WIDTH]));
    end
end

// Handling ack from destination
always @(posedge i_xclk_clk or posedge i_reset) begin
    if (i_reset) begin
        o_wb_ack <= 0;
        o_wb_data <= 0;
        o_wb_err <= 0;
    end else begin
        o_wb_ack <= 0;
        o_wb_err <= 0;
        if (i_xclk_ack) begin
            o_wb_ack <= 1;
            o_wb_data <= i_xclk_data;
            o_wb_err <= i_xclk_err;
        end
    end
end

endmodule
