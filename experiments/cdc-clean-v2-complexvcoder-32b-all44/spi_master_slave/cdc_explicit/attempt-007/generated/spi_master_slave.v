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
    reg [N-1:0]        shift_reg_mosi;
    reg [N-1:0]        shift_reg_miso;
    reg [N-1:0]        bit_cnt;
    reg [SPI_2X_CLK_DIV-1:0] sck_div_cnt;
    reg                  spi_sck_o_reg;
    reg                  spi_ssel_o_reg;
    reg                  di_req_o_reg;
    reg                  wr_ack_o_reg;
    reg                  do_valid_o_reg;
    reg [N-1:0]        do_o_reg;
    reg                  wren_i_sync;
    reg [N-1:0]        di_i_sync;
    reg                  miso_synced;

    // CDC for spi_miso_i
    cdc_sync cdc_sync_miso (
        .clk_i(sclk_i),
        .clk_o(pclk_i),
        .data_i(spi_miso_i),
        .data_o(miso_synced)
    );

    // CDC for wren_i
    cdc_sync cdc_sync_wren (
        .clk_i(pclk_i),
        .clk_o(sclk_i),
        .data_i(wren_i),
        .data_o(wren_i_sync)
    );

    // CDC for di_i
    cdc_sync #(N) cdc_sync_di (
        .clk_i(pclk_i),
        .clk_o(sclk_i),
        .data_i(di_i),
        .data_o(di_i_sync)
    );

    // State machine for SPI master
    typedef enum reg [2:0] {
        IDLE,
        START,
        TRANSFER,
        FINISH
    } state_t;

    state_t state, next_state;

    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        next_state = state;
        spi_sck_o_reg = spi_sck_o;
        spi_ssel_o_reg = spi_ssel_o;
        di_req_o_reg = di_req_o;
        wr_ack_o_reg = wr_ack_o;
        do_valid_o_reg = do_valid_o;
        do_o_reg = do_o;
        shift_reg_mosi = shift_reg_mosi;
        shift_reg_miso = shift_reg_miso;
        bit_cnt = bit_cnt;
        sck_div_cnt = sck_div_cnt;

        case (state)
            IDLE: begin
                spi_sck_o_reg = 0;
                spi_ssel_o_reg = 0;
                di_req_o_reg = 1;
                wr_ack_o_reg = 0;
                do_valid_o_reg = 0;
                do_o_reg = 0;
                shift_reg_mosi = di_i_sync;
                bit_cnt = N-1;
                sck_div_cnt = 0;

                if (wren_i_sync) begin
                    next_state = START;
                end
            end

            START: begin
                spi_sck_o_reg = 0;
                spi_ssel_o_reg = 1;
                di_req_o_reg = 0;
                wr_ack_o_reg = 1;
                do_valid_o_reg = 0;
                do_o_reg = 0;
                next_state = TRANSFER;
            end

            TRANSFER: begin
                if (sck_div_cnt == SPI_2X_CLK_DIV-1) begin
                    spi_sck_o_reg = ~spi_sck_o_reg;
                    sck_div_cnt = 0;

                    if (spi_sck_o_reg) begin
                        shift_reg_mosi = {shift_reg_mosi[N-2:0], 1'b0};
                        shift_reg_miso = {miso_synced, shift_reg_miso[N-1:1]};
                        if (bit_cnt == 0) begin
                            next_state = FINISH;
                        end else begin
                            bit_cnt = bit_cnt - 1;
                        end
                    end
                end else begin
                    sck_div_cnt = sck_div_cnt + 1;
                end
            end

            FINISH: begin
                spi_sck_o_reg = 0;
                spi_ssel_o_reg = 0;
                di_req_o_reg = 1;
                wr_ack_o_reg = 0;
                do_valid_o_reg = 1;
                do_o_reg = shift_reg_miso;
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end

    // Output assignments
    assign spi_sck_o = spi_sck_o_reg;
    assign spi_ssel_o = spi_ssel_o_reg;
    assign di_req_o = di_req_o_reg;
    assign wr_ack_o = wr_ack_o_reg;
    assign do_valid_o = do_valid_o_reg;
    assign do_o = do_o_reg;
    assign spi_mosi_o = shift_reg_mosi[N-1];

endmodule

module cdc_sync #(
    parameter WIDTH = 1
)(
    input              clk_i,
    input              clk_o,
    input  [WIDTH-1:0] data_i,
    output reg [WIDTH-1:0] data_o
);

    reg [WIDTH-1:0] sync_reg1, sync_reg2;

    always @(posedge clk_i) begin
        sync_reg1 <= data_i;
    end

    always @(posedge clk_o) begin
        sync_reg2 <= sync_reg1;
        data_o <= sync_reg2;
    end

endmodule
