module cdc_fifo_gray #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3,
    parameter SYNC_STAGES = 2
)(
    input                  src_rst_ni,
    input                  src_clk_i,
    input  [WIDTH-1:0]     src_data_i,
    input                  src_valid_i,
    output                 src_ready_o,
    input                  dst_rst_ni,
    input                  dst_clk_i,
    output [WIDTH-1:0]     dst_data_o,
    output                 dst_valid_o,
    input                  dst_ready_i
);

    // Internal signals
    wire [LOG_DEPTH-1:0] wr_ptr_gray_sync;
    wire [LOG_DEPTH-1:0] rd_ptr_gray_sync;

    // Gray counter for source domain
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) src_gray_counter (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .wr_en(src_ready_o & src_valid_i),
        .rd_en(dst_valid_o & dst_ready_i),
        .wr_ptr_gray(),
        .wr_ptr_bin(),
        .rd_ptr_gray(rd_ptr_gray_sync),
        .rd_ptr_bin(),
        .full(src_ready_o),
        .empty()
    );

    // Gray counter for destination domain
    gray_counter #(
        .LOG_DEPTH(LOG_DEPTH)
    ) dst_gray_counter (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .wr_en(),
        .rd_en(dst_valid_o & dst_ready_i),
        .wr_ptr_gray(wr_ptr_gray_sync),
        .wr_ptr_bin(),
        .rd_ptr_gray(),
        .rd_ptr_bin(),
        .full(),
        .empty(dst_valid_o)
    );

    // Synchronize write pointer to destination domain
    sync_stages #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_wr_ptr (
        .rst_ni(dst_rst_ni),
        .clk_i(dst_clk_i),
        .data_in(src_gray_counter.wr_ptr_gray),
        .data_out(wr_ptr_gray_sync)
    );

    // Synchronize read pointer to source domain
    sync_stages #(
        .WIDTH(LOG_DEPTH),
        .SYNC_STAGES(SYNC_STAGES)
    ) sync_rd_ptr (
        .rst_ni(src_rst_ni),
        .clk_i(src_clk_i),
        .data_in(dst_gray_counter.rd_ptr_gray),
        .data_out(rd_ptr_gray_sync)
    );

    // FIFO memory
    memory #(
        .WIDTH(WIDTH),
        .LOG_DEPTH(LOG_DEPTH)
    ) fifo_memory (
        .wr_clk_i(src_clk_i),
        .wr_rst_ni(src_rst_ni),
        .wr_data(src_data_i),
        .wr_addr(src_gray_counter.wr_ptr_bin),
        .wr_en(src_ready_o & src_valid_i),
        .rd_clk_i(dst_clk_i),
        .rd_rst_ni(dst_rst_ni),
        .rd_data(dst_data_o),
        .rd_addr(dst_gray_counter.rd_ptr_bin),
        .rd_en(dst_valid_o & dst_ready_i)
    );

endmodule

// Gray counter module
module gray_counter #(
    parameter LOG_DEPTH = 3
)(
    input                  rst_ni,
    input                  clk_i,
    input                  wr_en,
    input                  rd_en,
    output [LOG_DEPTH-1:0] wr_ptr_gray,
    output [LOG_DEPTH-1:0] wr_ptr_bin,
    output [LOG_DEPTH-1:0] rd_ptr_gray,
    output [LOG_DEPTH-1:0] rd_ptr_bin,
    output                 full,
    output                 empty
);

    reg [LOG_DEPTH-1:0] wr_ptr_bin_reg;
    reg [LOG_DEPTH-1:0] rd_ptr_bin_reg;

    // Gray encoding function
    function [LOG_DEPTH-1:0] bin_to_gray;
        input [LOG_DEPTH-1:0] bin;
        bin_to_gray = (bin >> 1) ^ bin;
    endfunction

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr_bin_reg <= {LOG_DEPTH{1'b0}};
            rd_ptr_bin_reg <= {LOG_DEPTH{1'b0}};
        end else begin
            if (wr_en)
                wr_ptr_bin_reg <= wr_ptr_bin_reg + 1;
            if (rd_en)
                rd_ptr_bin_reg <= rd_ptr_bin_reg + 1;
        end
    end

    assign wr_ptr_gray = bin_to_gray(wr_ptr_bin_reg);
    assign wr_ptr_bin  = wr_ptr_bin_reg;
    assign rd_ptr_gray = bin_to_gray(rd_ptr_bin_reg);
    assign rd_ptr_bin  = rd_ptr_bin_reg;

    assign full  = (wr_ptr_bin_reg == (rd_ptr_bin_reg + 1));
    assign empty = (wr_ptr_bin_reg == rd_ptr_bin_reg);

endmodule

// Synchronization stages module
module sync_stages #(
    parameter WIDTH = 8,
    parameter SYNC_STAGES = 2
)(
    input                  rst_ni,
    input                  clk_i,
    input  [WIDTH-1:0]     data_in,
    output [WIDTH-1:0]     data_out
);

    reg [WIDTH-1:0] sync_stages_reg [SYNC_STAGES-1:0];

    always @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            for (integer i = 0; i < SYNC_STAGES; i = i + 1)
                sync_stages_reg[i] <= {WIDTH{1'b0}};
        end else begin
            sync_stages_reg[0] <= data_in;
            for (integer i = 1; i < SYNC_STAGES; i = i + 1)
                sync_stages_reg[i] <= sync_stages_reg[i-1];
        end
    end

    assign data_out = sync_stages_reg[SYNC_STAGES-1];

endmodule

// Memory module
module memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  wr_clk_i,
    input                  wr_rst_ni,
    input  [WIDTH-1:0]     wr_data,
    input  [LOG_DEPTH-1:0] wr_addr,
    input                  wr_en,
    input                  rd_clk_i,
    input                  rd_rst_ni,
    output [WIDTH-1:0]     rd_data,
    input  [LOG_DEPTH-1:0] rd_addr,
    input                  rd_en
);

    reg [WIDTH-1:0] mem [0:(2**LOG_DEPTH)-1];

    always @(posedge wr_clk_i or negedge wr_rst_ni) begin
        if (!wr_rst_ni) begin
            for (integer i = 0; i < 2**LOG_DEPTH; i = i + 1)
                mem[i] <= {WIDTH{1'b0}};
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    reg [WIDTH-1:0] rd_data_reg;

    always @(posedge rd_clk_i or negedge rd_rst_ni) begin
        if (!rd_rst_ni)
            rd_data_reg <= {WIDTH{1'b0}};
        else if (rd_en)
            rd_data_reg <= mem[rd_addr];
    end

    assign rd_data = rd_data_reg;

endmodule
