module wbxclk #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
) (
    input wire i_wb_clk, i_reset,
    input wire i_wb_cyc, i_wb_stb, i_wb_we,
    input wire [(AW-1):0] i_wb_addr,
    input wire [(DW-1):0] i_wb_data,
    input wire [(DW/8-1):0] i_wb_sel,
    output wire o_wb_stall,
    output reg o_wb_ack,
    output reg [(DW-1):0] o_wb_data,
    output reg o_wb_err,
    input wire i_xclk_clk,
    output reg o_xclk_cyc,
    output reg o_xclk_stb,
    output reg o_xclk_we,
    output reg [(AW-1):0] o_xclk_addr,
    output reg [(DW-1):0] o_xclk_data,
    output reg [(DW/8-1):0] o_xclk_sel,
    input wire i_xclk_stall,
    input wire i_xclk_ack,
    input wire [(DW-1):0] i_xclk_data,
    input wire i_xclk_err
);

    wire wr_en, rd_en, stall, ack;
    reg [DW-1:0] wr_data_data;
    reg [AW-1:0] wr_data_addr;
    reg [DW/8-1:0] wr_data_sel;

    // FIFO to hold Wishbone transactions
    fifo #(
        .AW(AW),
        .DW(DW),
        .LGFIFO(LGFIFO)
    ) wb_to_xclk_fifo (
        .clk(i_wb_clk),
        .rst(i_reset),
        .wr_en(wr_en),
        .wr_data_addr(wr_data_addr),
        .wr_data_data(wr_data_data),
        .wr_data_sel(wr_data_sel),
        .rd_clk(i_xclk_clk),
        .rd_en(rd_en),
        .rd_addr(o_xclk_addr),
        .rd_data_data(o_xclk_data),
        .rd_data_sel(o_xclk_sel),
        .wr_full()
    );

    // Arbiter to handle Wishbone transactions
    arbiter #(
        .AW(AW),
        .DW(DW)
    ) wb_to_xclk_arbiter (
        .clk(i_wb_clk),
        .rst(i_reset),
        .req(i_wb_cyc & i_wb_stb),
        .ack(ack),
        .stall(stall),
        .data_in(i_wb_data),
        .addr_in(i_wb_addr),
        .sel_in(i_wb_sel),
        .we_in(i_wb_we),
        .data_out(o_xclk_data),
        .err_out(o_xclk_err),
        .cyc_out(o_xclk_cyc),
        .stb_out(o_xclk_stb),
        .we_out(o_xclk_we)
    );

    // Internal signals
    assign wr_en = i_wb_cyc & i_wb_stb;
    assign wr_data_data = i_wb_data;
    assign wr_data_addr = i_wb_addr;
    assign wr_data_sel = i_wb_sel;

    // Output stall signal
    assign o_wb_stall = stall;

    // Output ack signal
    always @(posedge i_wb_clk or posedge i_reset) begin
        if (i_reset) begin
            o_wb_ack <= 1'b0;
        end else begin
            o_wb_ack <= ack;
        end
    end

endmodule

module fifo #(
    parameter AW = 32,
    parameter DW = 32,
    parameter LGFIFO = 5
) (
    input wire clk,
    input wire rst,
    input wire wr_en,
    input wire [(AW-1):0] wr_data_addr,
    input wire [(DW-1):0] wr_data_data,
    input wire [(DW/8-1):0] wr_data_sel,
    input wire rd_clk,
    input wire rd_en,
    output reg [(AW-1):0] rd_addr,
    output reg [(DW-1):0] rd_data_data,
    output reg [(DW/8-1):0] rd_data_sel,
    output reg wr_full
);

    reg [LGFIFO-1:0] wr_ptr, rd_ptr;
    reg [LGFIFO-1:0] cnt;
    reg [(DW-1):0] mem [0:(1<<LGFIFO)-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            cnt <= 0;
            wr_full <= 1'b0;
        end else begin
            if (wr_en && !wr_full) begin
                mem[wr_ptr] <= wr_data_data;
                wr_ptr <= wr_ptr + 1;
                wr_full <= (wr_ptr == rd_ptr);
                cnt <= cnt + 1;
            end
        end
    end

    always @(posedge rd_clk or posedge rst) begin
        if (rst) begin
            rd_addr <= 0;
        end else begin
            if (rd_en && !wr_full) begin
                rd_addr <= rd_ptr;
                rd_ptr <= rd_ptr + 1;
                cnt <= cnt - 1;
            end
        end
    end

    assign rd_data_data = mem[rd_addr];
    assign rd_data_sel = wr_data_sel;

endmodule

module arbiter #(
    parameter AW = 32,
    parameter DW = 32
) (
    input wire clk,
    input wire rst,
    input wire req,
    output reg ack,
    output reg stall,
    input wire [(DW-1):0] data_in,
    input wire [(AW-1):0] addr_in,
    input wire [(DW/8-1):0] sel_in,
    input wire we_in,
    output reg [(DW-1):0] data_out,
    output reg err_out,
    output reg cyc_out,
    output reg stb_out,
    output reg we_out
);

    reg state;
    reg [DW-1:0] data_reg;
    reg [AW-1:0] addr_reg;
    reg [DW/8-1:0] sel_reg;
    reg we_reg;

    parameter IDLE = 2'b00;
    parameter GRANT = 2'b01;
    parameter BUSY = 2'b10;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            ack <= 1'b0;
            stall <= 1'b0;
            data_reg <= 0;
            addr_reg <= 0;
            sel_reg <= 0;
            we_reg <= 1'b0;
            cyc_out <= 1'b0;
            stb_out <= 1'b0;
            we_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (req) begin
                        state <= GRANT;
                        data_reg <= data_in;
                        addr_reg <= addr_in;
                        sel_reg <= sel_in;
                        we_reg <= we_in;
                        ack <= 1'b0;
                        stall <= 1'b0;
                        cyc_out <= 1'b1;
                        stb_out <= 1'b1;
                        we_out <= we_in;
                    end else begin
                        ack <= 1'b0;
                        stall <= 1'b0;
                        cyc_out <= 1'b0;
                        stb_out <= 1'b0;
                        we_out <= 1'b0;
                    end
                end
                GRANT: begin
                    if (stall) begin
                        state <= GRANT;
                        ack <= 1'b0;
                        stall <= 1'b1;
                        cyc_out <= 1'b1;
                        stb_out <= 1'b1;
                        we_out <= we_reg;
                    end else begin
                        state <= BUSY;
                        ack <= 1'b1;
                        stall <= 1'b0;
                        cyc_out <= 1'b0;
                        stb_out <= 1'b0;
                        we_out <= 1'b0;
                    end
                end
                BUSY: begin
                    if (!stall) begin
                        state <= IDLE;
                        ack <= 1'b0;
                        stall <= 1'b0;
                        cyc_out <= 1'b0;
                        stb_out <= 1'b0;
                        we_out <= 1'b0;
                    end else begin
                        state <= BUSY;
                        ack <= 1'b1;
                        stall <= 1'b1;
                        cyc_out <= 1'b0;
                        stb_out <= 1'b0;
                        we_out <= 1'b0;
                    end
                end
                default: begin
                    state <= IDLE;
                    ack <= 1'b0;
                    stall <= 1'b0;
                    cyc_out <= 1'b0;
                    stb_out <= 1'b0;
                    we_out <= 1'b0;
                end
            endcase
        end
    end

    assign data_out = data_reg;

endmodule
