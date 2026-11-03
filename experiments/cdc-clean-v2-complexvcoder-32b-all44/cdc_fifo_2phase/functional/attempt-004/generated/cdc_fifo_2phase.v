module cdc_fifo_2phase #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
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
    reg [LOG_DEPTH:0] wr_ptr_gray;
    reg [LOG_DEPTH:0] wr_ptr_gray_synced;
    reg [LOG_DEPTH-1:0] wr_ptr_bin;
    reg [LOG_DEPTH:0] rd_ptr_gray;
    reg [LOG_DEPTH:0] rd_ptr_gray_synced;
    reg [LOG_DEPTH-1:0] rd_ptr_bin;
    wire data_valid;

    // Sync write pointer to destination domain
    sync_bit sync_wr_ptr (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .din(wr_ptr_gray),
        .dout(wr_ptr_gray_synced)
    );

    // Sync read pointer to source domain
    sync_bit sync_rd_ptr (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .din(rd_ptr_gray_synced),
        .dout(rd_ptr_gray)
    );

    // Convert write pointer to binary
    gray_counter gray_counter_wr (
        .clk(src_clk_i),
        .rst_n(src_rst_ni),
        .gray(wr_ptr_gray),
        .bin(wr_ptr_bin)
    );

    // Convert read pointer to binary
    gray_counter gray_counter_rd (
        .clk(dst_clk_i),
        .rst_n(dst_rst_ni),
        .gray(rd_ptr_gray),
        .bin(rd_ptr_bin)
    );

    // FIFO memory
    fifo_memory fifo_mem (
        .wr_clk(src_clk_i),
        .wr_rst_n(src_rst_ni),
        .wr_ptr(wr_ptr_bin),
        .wr_en(src_valid_i),
        .wr_data(src_data_i),
        .rd_clk(dst_clk_i),
        .rd_rst_n(dst_rst_ni),
        .rd_ptr(rd_ptr_bin),
        .rd_en(dst_ready_i),
        .rd_data(dst_data_o),
        .data_valid(data_valid)
    );

    // Generate source ready signal
    always @(posedge src_clk_i or negedge src_rst_ni) begin
        if (!src_rst_ni) begin
            src_ready_o <= 1'b0;
        end else begin
            src_ready_o <= (wr_ptr_gray_synced != {1'b0, wr_ptr_bin + 1});
        end
    end

    // Generate destination valid signal
    always @(posedge dst_clk_i or negedge dst_rst_ni) begin
        if (!dst_rst_ni) begin
            dst_valid_o <= 1'b0;
        end else begin
            dst_valid_o <= data_valid;
        end
    end

endmodule

// Synchronize a single bit signal between two asynchronous clock domains
module sync_bit (
    input  clk,
    input  rst_n,
    input  din,
    output dout
);
    reg reg1;
    reg reg2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg1 <= 1'b0;
            reg2 <= 1'b0;
        end else begin
            reg1 <= din;
            reg2 <= reg1;
        end
    end

    assign dout = reg2;
endmodule

// Convert binary counter to gray code and vice versa
module gray_counter (
    input  clk,
    input  rst_n,
    input  [LOG_DEPTH:0] gray,
    output [LOG_DEPTH-1:0] bin
);
    reg [LOG_DEPTH-1:0] bin_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bin_reg <= {LOG_DEPTH{1'b0}};
        end else begin
            bin_reg <= gray ^ (gray >> 1);
        end
    end

    assign bin = bin_reg;
endmodule

// FIFO memory with asynchronous read and write
module fifo_memory #(
    parameter WIDTH = 8,
    parameter LOG_DEPTH = 3
)(
    input                  wr_clk,
    input                  wr_rst_n,
    input  [LOG_DEPTH-1:0] wr_ptr,
    input                  wr_en,
    input  [WIDTH-1:0]     wr_data,
    input                  rd_clk,
    input                  rd_rst_n,
    input  [LOG_DEPTH-1:0] rd_ptr,
    input                  rd_en,
    output [WIDTH-1:0]     rd_data,
    output                 data_valid
);
    reg [WIDTH-1:0] mem [0:(1<<LOG_DEPTH)-1];
    reg [WIDTH-1:0] rd_data_reg;
    reg data_valid_reg;

    always @(posedge wr_clk or negedge wr_rst_n) begin
        if (!wr_rst_n) begin
            mem <= '{default:0};
        end else if (wr_en) begin
            mem[wr_ptr] <= wr_data;
        end
    end

    always @(posedge rd_clk or negedge rd_rst_n) begin
        if (!rd_rst_n) begin
            rd_data_reg <= 0;
            data_valid_reg <= 0;
        end else begin
            rd_data_reg <= mem[rd_ptr];
            data_valid_reg <= rd_en;
        end
    end

    assign rd_data = rd_data_reg;
    assign data_valid = data_valid_reg;
endmodule
