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
    reg [1:0] spi_state, spi_state_next;
    reg [1:0] sclk_cnt;
    reg [3:0] bit_cnt;
    reg [N-1:0] data_out, data_in;
    reg wr_ack, do_valid, di_req;
    reg spi_ssel, spi_sck, spi_mosi;
    reg spi_miso_synced, wren_synced;
    reg [N-1:0] di_synced;

    // State definitions
    localparam IDLE     = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam RECEIVE  = 2'b10;
    localparam COMPLETE = 2'b11;

    // Clock-domain crossing
    cdc_sync wren_sync (
        .clk_src(pclk_i),
        .clk_dst(sclk_i),
        .rst(rst_i),
        .din(wren_i),
        .dout(wren_synced)
    );

    cdc_sync di_sync (
        .clk_src(pclk_i),
        .clk_dst(sclk_i),
        .rst(rst_i),
        .din(di_i[N-1]),
        .dout(di_synced[N-1])
    );

    genvar i;
    generate
        for (i = 0; i < N-1; i = i + 1) begin : gen_di_sync
            cdc_sync di_sync_bit (
                .clk_src(pclk_i),
                .clk_dst(sclk_i),
                .rst(rst_i),
                .din(di_i[i]),
                .dout(di_synced[i])
            );
        end
    endgenerate

    cdc_sync miso_sync (
        .clk_src(sclk_i),
        .clk_dst(pclk_i),
        .rst(rst_i),
        .din(spi_miso_i),
        .dout(spi_miso_synced)
    );

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
        spi_ssel = spi_ssel_o;
        spi_sck = spi_sck_o;
        spi_mosi = spi_mosi_o;
        wr_ack = 0;
        do_valid = 0;
        di_req = 0;

        case (spi_state)
            IDLE: begin
                spi_ssel = 0;
                spi_sck = 0;
                if (wren_synced) begin
                    spi_ssel = 1;
                    spi_state_next = TRANSFER;
                    wr_ack = 1;
                    di_req = 1;
                end
            end
            TRANSFER: begin
                if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                    spi_sck = ~spi_sck;
                    if (spi_sck) begin
                        spi_mosi = data_out[N-1-bit_cnt];
                        if (bit_cnt == N-1) begin
                            spi_state_next = RECEIVE;
                        end else begin
                            bit_cnt = bit_cnt + 1;
                        end
                    end
                    sclk_cnt = 0;
                end else begin
                    sclk_cnt = sclk_cnt + 1;
                end
            end
            RECEIVE: begin
                if (sclk_cnt == SPI_2X_CLK_DIV - 1) begin
                    spi_sck = ~spi_sck;
                    if (~spi_sck) begin
                        data_in = {data_in[N-2:0], spi_miso_synced};
                        if (bit_cnt == N-1) begin
                            spi_state_next = COMPLETE;
                        end else begin
                            bit_cnt = bit_cnt + 1;
                        end
                    end
                    sclk_cnt = 0;
                end else begin
                    sclk_cnt = sclk_cnt + 1;
                end
            end
            COMPLETE: begin
                spi_ssel = 0;
                do_valid = 1;
                spi_state_next = IDLE;
            end
        endcase
    end

    // Output assignments
    always @(posedge pclk_i or posedge rst_i) begin
        if (rst_i) begin
            di_req_o <= 0;
            wr_ack_o <= 0;
            do_valid_o <= 0;
            do_o <= 0;
        end else begin
            di_req_o <= di_req;
            wr_ack_o <= wr_ack;
            do_valid_o <= do_valid;
            if (spi_state == COMPLETE) begin
                do_o <= data_in;
            end
        end
    end

    // Output register assignments
    always @(posedge sclk_i or posedge rst_i) begin
        if (rst_i) begin
            data_out <= 0;
            bit_cnt <= 0;
            spi_ssel_o <= 0;
            spi_sck_o <= 0;
            spi_mosi_o <= 0;
        end else begin
            if (spi_state == IDLE && wren_synced) begin
                data_out <= di_synced;
                bit_cnt <= 0;
            end
            spi_ssel_o <= spi_ssel;
            spi_sck_o <= spi_sck;
            spi_mosi_o <= spi_mosi;
        end
    end

endmodule

module cdc_sync (
    input clk_src,
    input clk_dst,
    input rst,
    input din,
    output reg dout
);

    reg sync_reg1, sync_reg2;

    always @(posedge clk_src or posedge rst) begin
        if (rst) begin
            sync_reg1 <= 0;
        end else begin
            sync_reg1 <= din;
        end
    end

    always @(posedge clk_dst or posedge rst) begin
        if (rst) begin
            sync_reg2 <= 0;
        end else begin
            sync_reg2 <= sync_reg1;
        end
    end

    assign dout = sync_reg2;

endmodule
