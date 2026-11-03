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
    reg        di_req_pclk;
    reg        wr_ack_sclk;
    reg        do_valid_sclk;
    reg [N-1:0] do_sclk;
    reg        spi_ssel_sclk;
    reg        spi_sck_sclk;
    reg        spi_mosi_sclk;
    reg        spi_miso_sclk;
    reg [31:0] spi_clk_div;
    reg [4:0]  spi_bit_cnt;
    reg [N-1:0] spi_shift_reg;
    reg [1:0]  spi_state;
    reg [1:0]  spi_state_next;
    reg [N-1:0] spi_data_in;
    reg [N-1:0] spi_data_out;
    reg        spi_start_transfer;
    reg        spi_transfer_complete;

    // Clock domain crossing modules
    cdc cdc_di_req (
        .clk_i(pclk_i),
        .clk_o(sclk_i),
        .data_i(di_req_pclk),
        .data_o(di_req_o)
    );

    cdc cdc_wr_ack (
        .clk_i(sclk_i),
        .clk_o(pclk_i),
        .data_i(wr_ack_sclk),
        .data_o(wr_ack_o)
    );

    cdc cdc_do_valid (
        .clk_i(sclk_i),
        .clk_o(pclk_i),
        .data_i(do_valid_sclk),
        .data_o(do_valid_o)
    );

    cdc cdc_do (
        .clk_i(sclk_i),
        .clk_o(pclk_i),
        .data_i(do_sclk),
        .data_o(do_o)
    );

    // State definitions
    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam COMPLETE = 2'b10;

    // SPI clock generation
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_clk_div <= 0;
            spi_sck_o <= 0;
        end else begin
            if (spi_clk_div == SPI_2X_CLK_DIV - 1) begin
                spi_clk_div <= 0;
                spi_sck_o <= ~spi_sck_o;
            end else begin
                spi_clk_div <= spi_clk_div + 1;
            end
        end
    end

    // State machine
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_state <= IDLE;
        end else begin
            spi_state <= spi_state_next;
        end
    end

    always @(*) begin
        spi_state_next = spi_state;
        spi_start_transfer = 0;
        spi_transfer_complete = 0;
        spi_ssel_sclk = 0;
        spi_mosi_sclk = 0;

        case (spi_state)
            IDLE: begin
                if (spi_start_transfer) begin
                    spi_state_next = TRANSFER;
                    spi_ssel_sclk = 1;
                    spi_start_transfer = 1;
                end
            end
            TRANSFER: begin
                if (spi_bit_cnt == N - 1) begin
                    spi_state_next = COMPLETE;
                    spi_transfer_complete = 1;
                end else begin
                    spi_state_next = TRANSFER;
                end
                spi_mosi_sclk = spi_shift_reg[N - 1];
                spi_shift_reg = {spi_shift_reg[N - 2:0], spi_miso_sclk};
                spi_bit_cnt = spi_bit_cnt + 1;
            end
            COMPLETE: begin
                spi_state_next = IDLE;
                spi_ssel_sclk = 0;
                spi_bit_cnt = 0;
                spi_transfer_complete = 1;
            end
        endcase
    end

    // Data handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_data_in <= 0;
            spi_shift_reg <= 0;
        end else if (spi_start_transfer) begin
            spi_data_in <= di_i;
            spi_shift_reg <= di_i;
        end
    end

    // Output handling
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            do_sclk <= 0;
            wr_ack_sclk <= 0;
            do_valid_sclk <= 0;
        end else begin
            if (spi_transfer_complete) begin
                do_sclk <= spi_shift_reg;
                do_valid_sclk <= 1;
            end else begin
                do_valid_sclk <= 0;
            end
            if (spi_start_transfer) begin
                wr_ack_sclk <= 1;
            end else begin
                wr_ack_sclk <= 0;
            end
        end
    end

    // Request handling
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_pclk <= 1;
        end else begin
            if (spi_state == IDLE) begin
                di_req_pclk <= 1;
            end else begin
                di_req_pclk <= 0;
            end
        end
    end

    // SPI signal assignments
    assign spi_mosi_o = spi_mosi_sclk;
    assign spi_miso_sclk = spi_miso_i;
    assign spi_ssel_o = spi_ssel_sclk;

    // Start transfer detection
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            spi_start_transfer <= 0;
        end else begin
            if (spi_state == IDLE && wren_i && di_req_o) begin
                spi_start_transfer <= 1;
            end else begin
                spi_start_transfer <= 0;
            end
        end
    end

endmodule

module cdc (
    input clk_i,
    input clk_o,
    input data_i,
    output reg data_o
);

    reg data_sync1;
    reg data_sync2;

    always @(posedge clk_i) begin
        data_sync1 <= data_i;
        data_sync2 <= data_sync1;
    end

    always @(posedge clk_o) begin
        data_o <= data_sync2;
    end

endmodule
