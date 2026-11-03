module spi_master #(
    parameter N = 8,
    parameter SPI_2X_CLK_DIV = 2
)(
    input              sclk_i,
    input              pclk_i,
    input              rst_i,
    output reg         spi_ssel_o,
    output reg         spi_sck_o,
    output             spi_mosi_o,
    input              spi_miso_i,
    output reg         di_req_o,
    input  [N-1:0]     di_i,
    input              wren_i,
    output reg         wr_ack_o,
    output reg         do_valid_o,
    output reg [N-1:0] do_o
);

    // Internal signals
    reg [N-1:0]        shift_reg;
    reg                shift_reg_valid;
    reg [N-1:0]        pclk_to_sclk_fifo_data_out;
    reg                pclk_to_sclk_fifo_empty;
    reg                pclk_to_sclk_fifo_full;
    reg [N-1:0]        sclk_to_pclk_fifo_data_out;
    reg                sclk_to_pclk_fifo_empty;
    reg                sclk_to_pclk_fifo_full;
    reg [$clog2(SPI_2X_CLK_DIV)-1:0] bit_counter;
    reg                rst_sync_sclk_sync;
    reg                rst_sync_pclk_sync;
    reg                shift_reg_out_valid;

    // CDC synchronization for reset
    cdc_reg rst_sync_sclk (
        .async_in(rst_i),
        .clk(sclk_i),
        .sync_out(rst_sync_sclk_sync)
    );

    cdc_reg rst_sync_pclk (
        .async_in(rst_i),
        .clk(pclk_i),
        .sync_out(rst_sync_pclk_sync)
    );

    // CDC FIFO for data transfer from pclk to sclk
    cdc_fifo #(.N(N)) pclk_to_sclk_fifo (
        .write_clk(pclk_i),
        .write_data(di_i),
        .write_enable(wren_i),
        .write_rst(rst_sync_pclk_sync),
        .read_clk(sclk_i),
        .read_rst(rst_sync_sclk_sync),
        .read_data(pclk_to_sclk_fifo_data_out),
        .read_enable(1'b1),
        .read_data_valid(),
        .fifo_empty(pclk_to_sclk_fifo_empty),
        .fifo_full(pclk_to_sclk_fifo_full)
    );

    // CDC FIFO for data transfer from sclk to pclk
    cdc_fifo #(.N(N)) sclk_to_pclk_fifo (
        .write_clk(sclk_i),
        .write_data(shift_reg),
        .write_enable(shift_reg_valid),
        .write_rst(rst_sync_sclk_sync),
        .read_clk(pclk_i),
        .read_rst(rst_sync_pclk_sync),
        .read_data(sclk_to_pclk_fifo_data_out),
        .read_enable(1'b1),
        .read_data_valid(shift_reg_out_valid),
        .fifo_empty(sclk_to_pclk_fifo_empty),
        .fifo_full(sclk_to_pclk_fifo_full)
    );

    // SPI master control logic
    always @(posedge sclk_i or posedge rst_sync_sclk_sync) begin
        if (rst_sync_sclk_sync) begin
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
            bit_counter <= 0;
            shift_reg_valid <= 0;
        end else begin
            if (!fifo_empty) begin
                if (bit_counter == 0) begin
                    spi_ssel_o <= 1;
                    shift_reg <= pclk_to_sclk_fifo_data_out;
                    shift_reg_valid <= 1;
                end
                spi_sck_o <= ~spi_sck_o;
                if (spi_sck_o) begin
                    spi_mosi_o <= shift_reg[N-1];
                    shift_reg <= {shift_reg[N-2:0], 1'b0};
                    bit_counter <= bit_counter + 1;
                    if (bit_counter == SPI_2X_CLK_DIV - 1) begin
                        bit_counter <= 0;
                        if (shift_reg_valid) begin
                            shift_reg_valid <= 0;
                        end
                    end
                end
            end else begin
                spi_ssel_o <= 0;
            end
        end
    end

    // Parallel side control logic
    always @(posedge pclk_i or posedge rst_sync_pclk_sync) begin
        if (rst_sync_pclk_sync) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
        end else begin
            di_req_o <= shift_reg_valid;
            wr_ack_o <= wren_i & !pclk_to_sclk_fifo_full;
            do_valid_o <= shift_reg_out_valid;
            do_o <= sclk_to_pclk_fifo_data_out;
        end
    end

endmodule

// CDC register module
module cdc_reg (
    input  async_in,
    input  clk,
    output reg sync_out
);
    reg reg1, reg2;

    always @(posedge clk) begin
        reg1 <= async_in;
        reg2 <= reg1;
        sync_out <= reg2;
    end
endmodule

// CDC FIFO module
module cdc_fifo #(
    parameter N = 8,
    parameter FIFO_DEPTH = 16
)(
    input              write_clk,
    input  [N-1:0]     write_data,
    input              write_enable,
    input              write_rst,
    input              read_clk,
    input              read_rst,
    output reg [N-1:0] read_data,
    input              read_enable,
    output reg         read_data_valid,
    output reg         fifo_empty,
    output reg         fifo_full
);

    reg [$clog2(FIFO_DEPTH)-1:0] write_pointer;
    reg [$clog2(FIFO_DEPTH)-1:0] read_pointer;
    reg [$clog2(FIFO_DEPTH)-1:0] read_pointer_gray;
    reg [$clog2(FIFO_DEPTH)-1:0] read_pointer_gray_sync;
    reg [$clog2(FIFO_DEPTH)-1:0] write_pointer_gray;
    reg [N-1:0] fifo_mem [FIFO_DEPTH-1:0];

    // Gray code conversion
    function [$clog2(FIFO_DEPTH)-1:0] bin2gray;
        input [$clog2(FIFO_DEPTH)-1:0] bin;
        bin2gray = bin ^ (bin >> 1);
    endfunction

    // Write side logic
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst) begin
            write_pointer <= 0;
            write_pointer_gray <= 0;
            fifo_full <= 0;
        end else if (write_enable && !fifo_full) begin
            fifo_mem[write_pointer] <= write_data;
            write_pointer <= write_pointer + 1;
            write_pointer_gray <= bin2gray(write_pointer + 1);
        end
    end

    // Read side logic
    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            read_pointer <= 0;
            read_pointer_gray <= 0;
            read_data_valid <= 0;
            read_data <= 0;
            fifo_empty <= 1;
        end else begin
            read_pointer_gray_sync <= write_pointer_gray;
            if (read_enable && !fifo_empty) begin
                read_pointer <= read_pointer + 1;
                read_pointer_gray <= bin2gray(read_pointer + 1);
                read_data <= fifo_mem[read_pointer];
                read_data_valid <= 1;
            end else begin
                read_data_valid <= 0;
            end
        end
    end

    // FIFO status
    always @(posedge write_clk or posedge write_rst) begin
        if (write_rst) begin
            fifo_full <= 0;
        end else begin
            fifo_full <= (write_pointer_gray == bin2gray({read_pointer_gray_sync, 1'b1}));
        end
    end

    always @(posedge read_clk or posedge read_rst) begin
        if (read_rst) begin
            fifo_empty <= 1;
        end else begin
            fifo_empty <= (read_pointer_gray == write_pointer_gray);
        end
    end

endmodule
