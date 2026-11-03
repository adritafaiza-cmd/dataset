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

    reg [1:0] state;
    reg [2:0] count;
    reg [N-1:0] data_reg;
    reg [1:0] mosi_reg;
    reg [1:0] miso_reg;
    reg [N-1:0] shift_reg;
    reg [1:0] sclk_reg;
    reg [1:0] ssel_reg;
    reg di_valid;
    reg di_ready;
    reg wr_valid;
    reg wr_ready;
    reg do_ready;

    parameter IDLE = 2'b00;
    parameter SEND = 2'b01;
    parameter RECEIVE = 2'b10;

    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_ssel_o <= 1'b1;
            spi_sck_o <= 1'b0;
            spi_mosi_o <= 1'b0;
            di_req_o <= 1'b0;
            wr_ack_o <= 1'b0;
            do_valid_o <= 1'b0;
            state <= IDLE;
            count <= 3'b000;
            data_reg <= {N{1'b0}};
            shift_reg <= {N{1'b0}};
        end else begin
            case (state)
                IDLE:
                    begin
                        if (wren_i) begin
                            data_reg <= di_i;
                            di_valid <= 1'b1;
                            di_ready <= 0'b0;
                            state <= SEND;
                        end else begin
                            di_valid <= 1'b0;
                            di_ready <= 1'b1;
                        end
                    end
                SEND:
                    begin
                        spi_ssel_o <= 1'b0;
                        spi_sck_o <= 1'b0;
                        spi_mosi_o <= data_reg[count];
                        if (count == N) begin
                            state <= RECEIVE;
                        end else begin
                            count <= count + 1;
                            spi_sck_o <= 1'b1;
                        end
                    end
                RECEIVE:
                    begin
                        spi_sck_o <= 1'b0;
                        miso_reg <= spi_miso_i;
                        if (count == 0) begin
                            state <= IDLE;
                            wr_ack_o <= 1'b1;
                            do_valid_o <= 1'b1;
                            do_o <= shift_reg;
                        end else begin
                            shift_reg <= {shift_reg[N-2:0], miso_reg};
                            count <= count - 1;
                            spi_sck_o <= 1'b1;
                        end
                    end
            endcase
        end
    end

endmodule
